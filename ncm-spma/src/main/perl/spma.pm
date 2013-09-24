# ${license-info}
# ${developer-info}
# ${author-info}

#
# spma component - NCM SPMA configuration component
#
# generates the SPMA configuration file, runs SPMA if required.
#
################################################################################

package NCM::Component::spma;
#
# a few standard statements, mandatory for all components
#
use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element qw(unescape);

use NCM::Check;
use CAF::Process;
use LC::Exception qw(SUCCESS);
use LC::File qw(copy);
use File::Temp qw(tempfile tempdir);

File::Temp->safe_level( File::Temp::HIGH );

$NCM::Component::spma::NoActionSupported = 1;


# SPMA config files
my $spma_conf_file = '/etc/spma.conf';
my $spma_tcfg_file = '/var/lib/spma-target.cf';

# unescape by defaut
my $dounescape = 1;
my $trailprefix = 1;

#
# small helper function for unescaping chars
#
sub _unescape ($) {
    my $str=shift;

    if ($dounescape==0) {
        if ($trailprefix ==1 && $str =~ m%^_%) {
            return substr($str,1);
        } else {
            return $str;
        }
    }

    # call CCM's unescape
    $str = EDG::WP4::CCM::Element::unescape($str);
    return $str;
}


#
# get_repositories($config):ref(%hash)
#
# get a reference to a hash of hashes with the used repositories
#
# structure:
# $rep{repname}{protocol} = url
# eg.
# $rep{'CERN_CC'}{'http'} = 'http://swrep.cern.ch/swrep'
#
#
sub get_repositories($) {
    my ($self, $config) = @_;
    my %repository=();
    my $path='/software/repositories';
    my $rep_list = $config->getElement($path)->getTree();

    for my $rep (@{$rep_list}) {
        for my $prot (@{$rep->{protocols}}) {
            $self->debug(3, "repository: " . $rep->{name} . " at " . $prot->{url});
            $repository{$rep->{name}}{$prot->{name}}=$prot->{url};
        }
    }
    return \%repository;
}

#
# get_packages($config,$rep):ref(@array)
#
# returns a reference to an array with the list of
# target packages.
# each element of the array is a reference to a hash:
# 'name'    => package name    (eg. 'emacs')
# 'version' => version-release (eg. '20.4-3')
# 'arch'    => ref(%hash) with arch=>repository (eg. 'i386=>'repo_A', 'ia64'=>'repo_B')
# 'flags'   => ref(%hash) with flagtype=>value ('reboot'=>'true')
#
sub get_packages ($) {
    my ($self,$config,$rep) = @_;

    my $error = 0;
    my $path = '/software/packages';

    my @package_list = ();
    my $pkg_list = $config->getElement($path)->getTree();
    # Iterate over package names
    for my $pkg (sort keys %{$pkg_list}) {
        # Iterate over versions
        for my $ver (sort keys %{$pkg_list->{$pkg}}) {
            my $arch_list = {};
            my $arch = $pkg_list->{$pkg}->{$ver}->{arch};
            my $use_rep = '';
            # Single repository for all architectures
            if ( defined($pkg_list->{$pkg}->{$ver}->{repository}) ) {
                $use_rep = $pkg_list->{$pkg}->{$ver}->{repository};
            }
            # Architecture now available in three flavors
            if (ref($arch) eq 'HASH') {
                # Architecture comes from a nlist
                for my $i (keys %{$arch}) {
                    # Value is the repository name
                    $arch_list->{$i} = $arch->{$i};
                }
            } else {
                # No repository was specified
                if ( $use_rep eq '' ) {
                    if ( scalar(keys(%{$rep})) == 1 ) {
                        # One repository for all packages
                        $use_rep = (keys%{$rep})[0];
                    } else {
                        $EC->ignore_error();
                        $self->error('cannot guess repository for ' . &_unescape($pkg)
                            . '-' . &_unescape($ver));
                        $error++;
                        next;
                    }
                }
                if ( ref($arch) eq 'ARRAY') {
                    # Architecture comes from a list
                    for my $i (@{$arch}) {
                        $arch_list->{$i} = $use_rep;
                    }
                } else {
                    if ( $arch eq '' ) {
                        # Architecture comes from a property
                        $EC->ignore_error();
                        $self->error('empty architecture for ' . &_unescape($pkg)
                            . '-' . &_unescape($ver));
                        $error++;
                        next;
                    } else {
                        $arch_list->{$arch} = $use_rep;
                    }
                }
            }
            # Get flags, if any
            my %flags = ();
            if ( defined($pkg_list->{$pkg}->{$ver}->{flags}) ) {
                %flags = $pkg_list->{$pkg}->{$ver}->{flags};
            }
            # Output for debugging
            $self->debug(3, "package: " . &_unescape($pkg)
                . "; version: " . &_unescape($ver)
                . "; arch: " . join(',', keys %{$arch_list})
                . "; reps: " . join(',', values %{$arch_list})
                . "; flags: " . join(',', %flags));
            # Add to package list
            push(@package_list, {
                'name' => &_unescape($pkg),
                'version' => &_unescape($ver),
                'arch' => $arch_list,
                'flags' => \%flags});
        }
    }
    return $error ? undef : \@package_list;
}


#
# run the SPMA. $sconf_file (SPMA's configuration file), and $stcfg_file (target
# configuration file) are used *only* in noaction mode; otherwise, the default
# locations are used
#
sub run_spma($$$) {
    my ($self, $sconf_file, $stcfg_file) = @_;

    my ($stdout, $stderr);

    my $spma_exec= CAF::Process->new(["/usr/bin/spma"],
				     log => $self,
				     timeout => 8000,
				     stdout => \$stdout,
				     stderr => \$stderr);

    # command line options to ncm-ncd override whatever we have in the
    # config file
    if($main::this_app->option("quiet")) {
	$spma_exec->pushargs("--quiet");
    } else {
	if ($main::this_app->option("verbose")) {
	    $spma_exec->pushargs("--verbose");
	}
	if($main::this_app->option("debug")) {
	    $spma_exec->pushargs("--debug",$main::this_app->option("debug"));
	}
    }
    $self->info("running the SPMA");

    if ($NoAction) {
	$spma_exec->pushargs("--noaction",
			     "--cfgfile=$sconf_file",
			     "--targetconf=$stcfg_file");
        $self->info('running SPMA in noaction mode');
    }

    my $execute_status = $spma_exec->execute();

    my $retval=$?;
    unless (defined $execute_status && $execute_status) {
        $self->error("Could not execute SPMA");
        return;
    }
    if ($stdout) {
        $self->info("SPMA output produced: (please check spma.log)");
        $self->report($stdout);
    }
    if ($stderr) {
        $self->warn("SPMA STDERR output produced: (please check spma.log)");
        $self->report($stderr);
    }
    if ($retval) {
        $self->error("SPMA failed with exit status $retval ",
		     "(please check spma.log)");
    } else {
        $self->OK("SPMA finished succesfully (please check spma.log)");
    }
}


# update_spmaconf_file($config, $conffile)
#
# update the SPMA configuration file $conffile with info coming from $config.
#
sub update_spmaconf_file($$$) {
    my ($self, $config, $conffile) = @_;

    my @keys=qw(userpkgs userprio packager usespmlist rpmexclusive debug verbose
                cachedir localcache headnode
                proxy proxytype proxyhost proxyport proxyrandom
                checksig protectkernel);

    unless (-e $conffile && -w $conffile) {
        $self->warn('does not exist or cannot write to: '.$conffile);
        return;
    }

    my $i;
    my %key;
    foreach $i (@keys) {
        my $cfgel=$config->getElement('/software/components/spma/'.$i);
        unless (defined $cfgel) {
            $EC->ignore_error();
            next;
        } else {
            $key{$i}=$cfgel->getValue();
        }
    }
    #
    # if using a headnode, then set proxyhost to it
    #
    if (exists $key{'headnode'} && $key{'headnode'} eq 'true') {
        unless ($config->elementExists('/hardware/headnode/name')) {
            $self->warn('head node activated, but none found in /hardware/headnode/name');
            $key{'proxy'}="no";
            $key{'proxyhost'}='undefined';
        } else {
            $key{'proxyhost'}=$config->getValue('/hardware/headnode/name');
        }
    }
    delete $key{'headnode'}; # as not part of SPMA config file

    foreach $i (keys %key) {
        NCM::Check::lines(
            $conffile,
# backup is useless, since it's overwritten at each iteration
#             backup => ".old",
            linere      => '^#?\s*'.$i.'(\s+|=).*',
            goodre      => '^\s*'.$i.'\s*=\s*'.$key{$i},
            good        => "$i = ".$key{$i},
            add         => 'last',
            # we want to actually do the changes since we're (supposedly)
            # working on tmp files
            noaction    => 0
        );
    }

    return SUCCESS;
}


# write_trgtconf_file($hr_rep, $ar_pgks, $trgt_fh)
#
# update the SPMA's target configuration file pointed by the file handle
# $trgt_fh with the package list referenced by $ar_pgks and repository
# information coming from the hash reference $hr_rep
sub write_trgtconf_file($$$) {
    my ($self, $hr_rep, $ar_pgks, $trgt_fh) = @_;

    print $trgt_fh "#\n#\n# generated by NCM SPMA component at "
        . scalar(localtime) . "\n#\n#\n";
    my ($i, $ver, $rel);
    foreach $i (@$ar_pgks) {
        # SPMA wants separate version and release
        ($ver, $rel) = split('-', $i->{'version'});
        # Flags
        my (@flags, $f);
        foreach $f (keys %{$i->{'flags'}}) {
            if ($i->{'flags'}->{$f} eq 'true') {
                push(@flags, uc($f));
            }
        }
        # Print one line per architecture
        for my $arch ( sort keys %{$i->{'arch'}} ) {
            my $rep = $i->{'arch'}->{$arch};
            # Check protocol is 'http'
            unless ( exists($hr_rep->{$rep}{'http'}) ) {
                # this is arbitrary. In a next version,
                # there should be the possibility of specifying
                # which protocols are acceptable (ordered list)
                $self->error ("no HTTP protocol found for repository " . $rep);
                return;
            }
            # Line to print
            my $line = $hr_rep->{$rep}{'http'} . ' ' .$i->{'name'} . ' '
                . $ver . ' ' . $rel . ' ' . $arch . ' ' . join(' ', @flags);
            # Output for debugging
            $self->debug(4, $line);
            # Print to file handle
            print $trgt_fh $line . "\n";
        }
    }

    return SUCCESS;
}


##########################################################################
sub Configure {
##########################################################################
    my ($self,$config)=@_;

    unless ($config->elementExists('/software/packages') &&
            $config->elementExists('/software/repositories')) {
        $self->info("/software/repositories or /software/packages ",
		    "does not exist, skipping SPMA configuration");
        return;
    }

    my $tmpdir;
    if ($config->elementExists('/software/components/spma/tmpdir')) {
        $tmpdir = $config->getElement('/software/components/spma/tmpdir')->getValue();
        $self->debug(1, "tmpdir defined in spma : $tmpdir");
        mkdir $tmpdir, 0755 if (! -e $tmpdir );
    } else {
        $tmpdir = "/tmp";
        $self->debug(1, "tmpdir not defined in spma : using $tmpdir");
    }
    #
    # update the spma config file
    #
    my ($tscfh, $tmp_scnf_fn) = tempfile('spma.conf.XXXX', DIR => $tmpdir, UNLINK => 1);
    $self->debug(1, "created tmp file $tmp_scnf_fn");
    # we don't need the file handle
    unless(close($tscfh)) {
        $self->error("cannot close $tmp_scnf_fn");
        return;
    }
    # prepare a copy of the original file to work upon
    unless(copy($spma_conf_file, $tmp_scnf_fn)) {
        $self->error("cannot copy $spma_conf_file to temporary $tmp_scnf_fn: $!");
        return;
    }
    unless($self->update_spmaconf_file($config, $tmp_scnf_fn)) {
        $self->error("cannot update SPMA's configuration file $tmp_scnf_fn");
        return;
    }
    $self->verbose("updated SPMA configuration file in $tmp_scnf_fn");

    # do we need to escape chars?
    if ($config->elementExists('/software/components/spma/unescape') &&
        $config->getValue('/software/components/spma/unescape') eq 'false') {
        $dounescape=0;
    }

    # do we need to remove a trailing underscore? (only if no unescape())
    if ($config->elementExists('/software/components/spma/trailprefix') &&
        $config->getValue('/software/components/spma/trailprefix') eq 'false') {
        $trailprefix=0;
    }


    my $rep = $self->get_repositories($config);
    unless (defined $rep) {
        $self->error ('could not get repository information');
        return;
    }

    my $pkgs=$self->get_packages($config,$rep);

    unless (defined $pkgs) {
        $self->error('error generating package list - preserving old one');
        return;
    }

    #
    # build the target config file
    #
    my ($ttcfh, $tmp_tcfg_fn) = tempfile('spma-target.cf.XXXX', DIR => $tmpdir, UNLINK => 1);
    $self->debug(1, "created tmp file $tmp_tcfg_fn");
    unless($self->write_trgtconf_file($rep, $pkgs, $ttcfh)) {
        $self->error("cannot write target configuration file $tmp_tcfg_fn");
        return;
    }
    $self->verbose("created SPMA target configuration file in $tmp_tcfg_fn");
    unless(close($ttcfh)) {
        $self->error("cannot close $tmp_tcfg_fn");
        return;
    }

    if($NoAction) {
        # configuration is taken from temporary files
        $spma_tcfg_file = $tmp_tcfg_fn;
        $spma_conf_file = $tmp_scnf_fn;
    } else {
        # overwrite the original configuration files
        unless(copy($tmp_scnf_fn, $spma_conf_file)) {
            $self->error("cannot copy temporary $tmp_scnf_fn to $spma_conf_file: $!");
            return;
        }
        $self->OK("updated SPMA configuration file $spma_conf_file");
        unless(copy($tmp_tcfg_fn, $spma_tcfg_file)) {
            $self->error("cannot copy temporary $tmp_tcfg_fn to $spma_tcfg_file: $!");
            return;
        }
        $self->OK("updated SPMA target configuration file in $spma_tcfg_file");
    }

    if ($config->elementExists('/software/components/spma/run') &&
        $config->getValue('/software/components/spma/run') eq 'yes') {
        # parameters are used only in noaction mode
        $self->run_spma($spma_conf_file, $spma_tcfg_file);
    }

    return;
}

1; # required for Perl modules
