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
use LC::Process;
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

my $tempdir = '/tmp';

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

    #
    # get the repositories
    #
    my %repository=();

    my $path='/software/repositories';

    my $rep_list=$config->getElement($path);
    unless (defined $rep_list) {
        $EC->ignore_error();
        $self->error('cannot access config path: '.$path);
        return undef;
    }

    my ($rep_el,$rep_el_name,$rep_name,$rep_name_str,$url);
    my ($rep_prot,$rep_prot_entry,$rep_prot_entry_name,$rep_prot_url);
    my ($rep_prot_name,$rep_prot_name_str);

    #
    # the NVA API navigation functions would profit from
    # shortcut methods for relative navigation,
    # something like
    #
    # $newelement=$oldelement->down('relative/path')
    #
    # and probably also
    #
    # $newelvalue=$oldelement->downvalue('relative/path');
    #
    # instead of having to instantiate a new element from
    # $config
    #

    while($rep_list->hasNextElement()) {
        $rep_el=$rep_list->getNextElement();
        $rep_el_name=$rep_el->getName();
        $rep_name=$config->getElement($path.'/'.$rep_el_name.'/name');
        $rep_name_str=$rep_name->getValue();

        $rep_prot=$config->getElement($path.'/'.$rep_el_name.'/protocols');
        while ($rep_prot->hasNextElement()) {
            $rep_prot_entry=$rep_prot->getNextElement();
            $rep_prot_entry_name=$rep_prot_entry->getName();
            $rep_prot_name=$config->getElement
                ($path.'/'.$rep_el_name.'/protocols/'.
                $rep_prot_entry_name.'/name');
            $rep_prot_url=$config->getElement
                ($path.'/'.$rep_el_name.'/protocols/'.
                $rep_prot_entry_name.'/url');
            $repository{$rep_name_str}{$rep_prot_name->getValue()}=
                $rep_prot_url->getValue();
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
# 'rep'     => repository name (eg. 'CERN_CC')
# 'name'    => package name    (eg. 'emacs')
# 'version' => version-release (eg. '20.4-3')
# 'arch'    => ref(@array) with architectures (eg. i386,ia64)
#
# 'flags'   => flags ref(%hash) with flagtype=>value ('reboot'=>'true')
#
sub get_packages ($) {
    my ($self,$config,$rep)=@_;

    my @pkg_list=();

    my $error=0;
    my $path='/software/packages';

    my ($pkg_el,$pkg_name,$pkg_verlist,$pkgver,$pkgver_name);
    my ($pkgver_arch,$pkgver_rep,$pkg_flaglist,$pkg_flag,$use_rep);

    my $pkg_list=$config->getElement($path);
    while ($pkg_list->hasNextElement()) {
        $pkg_el=$pkg_list->getNextElement();
        $pkg_name=$pkg_el->getName();
        #
        # go for the versions
        #
        $pkg_verlist=$config->getElement($path.'/'.$pkg_name);

        while($pkg_verlist->hasNextElement()) {
            $pkgver=$pkg_verlist->getNextElement();
            $pkgver_name=$pkgver->getName();

            $self->debug(3,"package: $pkg_name version: $pkgver_name");
            $pkgver_arch=$config->getElement($path.'/'.$pkg_name.
                                            '/'.$pkgver_name.'/arch');
            if (!defined $pkgver_arch) {
                $self->error('cannot get architecture for '.
                            &_unescape($pkg_name).'-'.&_unescape($pkgver_name));
                $error++;
                next;
            }
            my @arch_list=();
            if ($pkgver_arch->isProperty()) {
                # "classic" schema
                # arch is a property and specifies directly an architecture
                if ($pkgver_arch->getValue() eq '') {
                    $EC->ignore_error();
                    $self->error('empty architecture for '.
                                &_unescape($pkg_name).'-'.&_unescape($pkgver_name));
                    $error++;
                    next;
                } else {
                    @arch_list=($pkgver_arch->getValue());
                }
            } else {
                # "new" schema
                # arch is a list of architectures
                @arch_list=map {$_->getValue()} ($pkgver_arch->getList());
                $self->debug(3,"        arch: ".join (',',@arch_list));
            }

            $pkgver_rep=$config->getElement($path.'/'.$pkg_name.
                                            '/'.$pkgver_name.'/repository');
            if (!defined $pkgver_rep || $pkgver_rep->getValue() eq '') {
                $EC->ignore_error();
                #
                # if more than one repository available, give up, otherwise
                # assume unique repository is the one to use
                #
                my @reps=keys %{$rep};
                if (scalar @reps >1) {
                    $self->error('cannot guess repository for '.
                                &_unescape($pkg_name).'-'.&_unescape($pkgver_name));
                    $error++;
                    next;
                } else {
                    $use_rep=$reps[0];
                }
            } else {
                $use_rep=$pkgver_rep->getValue();
            }
            #
            # get the per package flags, if any
            #
            my %flags=();
            unless ($pkg_flaglist=$config->getElement($path.'/'.$pkg_name.
                                                    '/'.$pkgver_name.'/flags')) {
                $EC->ignore_error();
            } else {
                while ($pkg_flaglist->hasNextElement()) {
                    $pkg_flag=$pkg_flaglist->getNextElement();
                    $flags{$pkg_flag->getName()}=$pkg_flag->getValue();
                }
            }

            push(@pkg_list, {
                    'rep'     => $use_rep,
                    'name'    => &_unescape($pkg_name),
                    'version' => &_unescape($pkgver_name),
                    'arch'    => \@arch_list,
                    'flags'   => \%flags,
                }
            );
        }
    }
    return $error ? undef : \@pkg_list;
}


#
# run the SPMA. $sconf_file (SPMA's configuration file), and $stcfg_file (target
# configuration file) are used *only* in noaction mode; otherwise, the default
# locations are used
#
sub run_spma($$$) {
    my ($self, $sconf_file, $stcfg_file) = @_;

    my $spma_exec="/usr/bin/spma --quiet";
    $self->info("running the SPMA: '$spma_exec'");

    if ($NoAction) {
        $spma_exec .= " --noaction" .
            " --cfgfile=$sconf_file".
            " --targetconf=$stcfg_file";
        $self->info('running SPMA in noaction mode');
    }

    my ($stdout,$stderr);
    my $execute_status = LC::Process::execute(
        [$spma_exec],
        timeout => 8000,
        stdout => \$stdout,
        stderr => \$stderr
    );

    my $retval=$?;
    unless (defined $execute_status && $execute_status) {
        $self->error("could not execute $spma_exec");
        return;
    }
    if ($stdout) {
        $self->info("'$spma_exec' output produced: (please check spma.log)");
        $self->report($stdout);
    }
    if ($stderr) {
        $self->warn("'$spma_exec' STDERR output produced: (please check spma.log)");
        $self->report($stderr);
    }
    if ($retval) {
        $self->error("'$spma_exec' failed with exit status $retval (please check spma.log)");
    } else {
        $self->OK("'$spma_exec' finished succesfully (please check spma.log)");
    }
}


# update_spmaconf_file($config, $conffile)
#
# update the SPMA configuration file $conffile with info coming from $config.
#
sub update_spmaconf_file($$$) {
    my ($self, $config, $conffile) = @_;

    my @keys=qw(userpkgs userprio packager usespmlist rpmexclusive debug verbose
                cachedir localcache proxy proxytype proxyhost proxyport headnode
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

    print $trgt_fh "#\n#\n# generated by NCM SPMA component at ".scalar(localtime)."\n#\n#\n";
    my ($i, $ver, $rel);
    foreach $i (@$ar_pgks) {
        # SPMA wants separate version and release
        ($ver,$rel) = split('-',$i->{'version'});
        unless (exists($hr_rep->{$i->{'rep'}}{'http'})) {
            $self->error ("no HTTP protocol found for repository ".$i->{'rep'});
            return;
            # this is arbitrary. In a next version,
            # there should be the possibility of specifying
            # which protocols are acceptable (ordered list)
        }

        #
        # flags
        #
        my (@flags,$f);
        foreach $f (keys %{$i->{'flags'}}) {
            if ($i->{'flags'}->{$f} eq 'true') {
                push(@flags,uc($f));
            }
        }

        my $arch;
        foreach $arch (@{$i->{'arch'}}) {
            print $trgt_fh $hr_rep->{$i->{'rep'}}{'http'} .' '.$i->{'name'}.
                ' '.$ver.' '.$rel.' '.$arch.' '.
                join(' ',@flags)."\n";
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
        $self->info("/software/repositories or /software/packages does not exist, skipping SPMA configuration");
        return;
    }

    #
    # update the spma config file
    #
    my ($tscfh, $tmp_scnf_fn) = tempfile('spma.conf.XXXX', DIR => $tempdir, UNLINK => 1);
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
    my ($ttcfh, $tmp_tcfg_fn) = tempfile('spma-target.cf.XXXX', DIR => $tempdir, UNLINK => 1);
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
