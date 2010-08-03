# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::squid - NCM Squid proxy-caching server configuration component
#
###############################################################################

package NCM::Component::squid;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use CAF::Process;
use LC::File qw(copy destroy differ file_contents makedir move path_for_open remove);
use LC::Fatal qw(chown);
use POSIX;

############################################################################
# Globals
my $squidConfFilePath = '/etc/squid/squid.conf';
my $squidCDefFilePath = '/etc/squid/squid.conf.default';
my $squidCBakFilePath = '/etc/squid/squid.conf.ncm-saved';
my $squidCTmpFilePath = '/var/ncm/tmp/squid.conf.tmp';
my $squidSignFilePath = '/etc/squid/.ncm-squid.sig';
my $squid_user = 'squid';
my $squidDefSwapDir = '/var/spool/squid';
my $squidDefSwapPar = '100 16 256';


############################################################################
# Local functions

# Remove temporary files. Do a deep clean if the second input parameter is > 0.
sub cleanup {
    my ($self, $deep) = @_;

    if($deep) {
        if(-e $squidSignFilePath) {
            unless(remove($squidSignFilePath)) {
                $self->error("cannot remove $squidSignFilePath");
                return 0;
            }
        }
        if(-e $squidCBakFilePath) {
            unless(move($squidCBakFilePath, $squidConfFilePath)) {
                $self->error("cannot restore $squidConfFilePath");
                return 0;
            }
        }
    }
    if(-e $squidCTmpFilePath) {
        unless(remove($squidCTmpFilePath)) {
            $self->error("cannot remove $squidCTmpFilePath");
            return 0;
        }
    }
    return 1;
}


# Get swap configuration, extracting 'cache_dir' directive infos from the input
# file. If the third input parameter is >0, directory existence is checked.
# The returned hash is structured this way:
#   key     -> 'directory' path (string)
#   value   -> 'MB L1 L2' parameters (string)
sub get_swap_config {
    my ($self, $cfile, $exist) = @_;
    my %sdirs = ();

    unless(defined($exist)) {
            $self->error("get_swap_config: 'exist' parameter undefined");
            $sdirs{'_ERROR_'} = 1;
            return %sdirs;
    }
    unless(open(CFILE, '<', path_for_open($cfile))) {
            $self->error("get_swap_config: cannot open $cfile");
            $sdirs{'_ERROR_'} = 1;
            return %sdirs;
    }
    # look for any uncommented 'cache_dir' directive
    while(<CFILE>) {
        chomp;
        if(/^\s*cache_dir\s+/) {
            my ($cdir, @cpar) = (split(/\s+/))[2, 3, 4, 5];
            if($exist) {
                # add only existing dirs
                $sdirs{$cdir} = join(' ', @cpar) if(-e $cdir);
            }
            else {
                $sdirs{$cdir} = join(' ', @cpar);
            }
        }
    }
    return %sdirs;
}


##########################################################################
sub Configure {
##########################################################################
    my ($self, $config)=@_;

    # There are 3 directive groups: basic, size and multi.
    # [basic] simple two-token options which may appear only once.
    # [size] options which affect the cache size and should appear only once:
    # these are two-token-based, but a third token KB will be
    # added.
    # [multi] options which may appear more than once, usually composed
    # of a variable number of tokens.
    #
    # BIG WARNING!!! Since there is not yet support for a context-dependant
    # patching mechanism in LC::File, this component relies on
    # directive lines which *must* be present in the config file (even though
    # commented). For this reason, on its first run, the component will use the
    # default Squid config file, and place a signature file in the config
    # directory.
    #
    # Basic workflow. Create a temporary backup of the config file with all
    # the needed changes with respect to the existing one. If modifications
    # have occurred, replace the previous config file and restart the service.
    # When un-configuring, restore the original config file from the default
    # config and delete the signature file.


    my $reload = 0;
    my %current_swaps = ();
    my %new_swaps = ();
    my $first_run = 0;
    my $cmd = '';
    my $is_stopped = 0;

    ############################################################################
    # Initialization.

    # check now if squid is running
    CAF::Process->new([qw(/sbin/service squid status)],
		      log => $self)->run();
    if ($? &&  WEXITSTATUS($?) != 3) {
        $self->error("Failed to check squid daemon status");
        $self->cleanup($first_run);
        return;
    }
    $is_stopped = 0;

    # Look for the signature file.
    unless(-e $squidSignFilePath) {
        $first_run = 1;
        # save the config file and replace it with the default one
        unless(copy($squidConfFilePath, $squidCBakFilePath)) {
            $self->error("cannot create $squidCBakFilePath");
            $self->cleanup($first_run);
            return;
        }
        unless(copy($squidCDefFilePath, $squidConfFilePath)) {
            $self->error("cannot create $squidConfFilePath");
            $self->cleanup($first_run);
            return;
        }
        # put a signature file in place. Record here the otiginal status
        unless(open(SFILE, '>', path_for_open($squidSignFilePath))) {
            $self->error("cannot create $squidSignFilePath");
            $self->cleanup($first_run);
            return;
        }
        print(SFILE <<EOF
# ncm-squid - signature file
# DO NOT REMOVE!
WAS_STOPPED=$is_stopped
EOF
        );
        close(SFILE);
    }

    # Get literal u/gid for the squid user
    my ($squid_uid, $squid_gid) = (getpwnam($squid_user))[2, 3];
    unless(defined($squid_uid) and defined($squid_gid)) {
        $self->error("cannot get 'squid' uid/gid");
        $self->cleanup( $first_run);
        return;
    }
    $self->debug(5, "squid_uid = $squid_uid, squid_gid = $squid_gid");

    # all modifications are done to a temporary file
    unless(copy($squidConfFilePath, $squidCTmpFilePath)) {
        $self->error("cannot create $squidCTmpFilePath");
        $self->cleanup($first_run);
        return;
    }


    ##############################
    # 'basic' directive processing
    ##############################
    # Two-tokens context-independant options: they can stay everywhere but
    # should appear once.
    my $basicValPath = '/software/components/squid/basic';

    # this is optional
    if($config->elementExists($basicValPath)) {
        my $bre = $config->getElement($basicValPath);

        # walk through the options
        while($bre->hasNextElement()) {
            my $bce = $bre->getNextElement();
            my $boptname = $bce->getName();
            unless($bce->isProperty()) {
                $self->error("$boptname is not a property");
                $self->cleanup($first_run);
                return;
            }
            my $bval = $bce->getValue();
            $self->debug(5, "BASIC property: $boptname = $bval");
            # These shouldn't be context-dependant, so can be also appended
            NCM::Check::lines($squidCTmpFilePath,
                        linere => '\W*\s*'.$boptname.'\s+.+',
                        goodre => '\s*'.$boptname.'\s+'.quotemeta($bval),
                        good   => "$boptname $bval",
                        keep   => 'first',
                        add    => 'last'
                    );
        }
    }


    ##############################
    # 'size' directive processing
    ##############################
    # Three-tokens context-independant options: they can stay everywhere but
    # should appear once. Only the first two tokens come from templates, the
    # third (specifying the size unit) is added here.
    my $sizeValPath = '/software/components/squid/size';

    # this is optional
    if($config->elementExists($sizeValPath)) {
        my $sre = $config->getElement($sizeValPath);

        # walk through the options
        while($sre->hasNextElement()) {
            my $sce = $sre->getNextElement();
            my $soptname = $sce->getName();
            unless($sce->isProperty()) {
                $self->error("$soptname is not a property");
                $self->cleanup($first_run);
                return;
            }
            my $sval = $sce->getValue();
            $self->debug(5, "SIZE property: $soptname = $sval [KB]");
            # These shouldn't be context-dependant, so can be also appended
            NCM::Check::lines($squidCTmpFilePath,
                        linere => '\W*\s*'.$soptname.'\s+.+',
                        goodre => '\s*'.$soptname.'\s+'.quotemeta($sval).'\s+KB',
                        good   => "$soptname $sval KB",
                        keep   => 'first',
                        add    => 'last'
                    );
        }
    }


    ##############################
    # 'multi' directive processing
    ##############################
    # Multi-tokens options: they can may appear several time.
    # WARNING! Some of them are *context-dependant* BUT no support is available
    # to date in LC::File. The declaration template supports multiple lines, BUT
    # no guarantee is given on the correct placement, so only one line should be
    # given!!!
    my $multiValPath = '/software/components/squid/multi';

    # some stuff is mandatory here
    unless($config->elementExists($multiValPath)) {
        $self->error("cannot get $multiValPath. At least one 'acl' and one 'http_access' are needed");
        $self->cleanup($first_run);
        return;
    }

    my $mre = $config->getElement($multiValPath);

    # walk through the options
    while($mre->hasNextElement()) {
        my $mce = $mre->getNextElement();
        my $moptname = $mce->getName();
        unless($mce->isResource()) {
            $self->error("$moptname is not a resource");
            $self->cleanup($first_run);
            return;
        }
        $self->debug(5, "MULTI resource: $moptname");
        # these directives need special parsing...
        # TODO.Since multiple directives are allowed, and more than one token can
        # be matched in each line, try to match most of the line and then
        # erase any similar uncommented non-matching lines.
        if($moptname eq 'acl') {
            while($mce->hasNextElement()) {
                my $acl = $mce->getNextElement();
                my %entry = $acl->getHash();

                my $property = $entry{name};
                unless(defined($property)) {
                    $self->error("undefined name for acl");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("name is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $name = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.name=$name");

                $property = $entry{type};
                unless(defined($property)) {
                    $self->error("undefined type for acl");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("type is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $type = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.type=$type");

                # more targets might be provided
                my $resource = $entry{targets};
                unless(defined($resource)) {
                    $self->error("undefined targets for acl");
                    $self->cleanup($first_run);
                    return;
                }
                unless($resource->isResource()) {
                    $self->error("targets is not a resource");
                    $self->cleanup($first_run);
                    return;
                }
                my @targets = ();
                while($resource->hasNextElement()) {
                    my $targ = $resource->getNextElement();
                    unless($targ->isProperty()) {
                        $self->error("target is not a property");
                        $self->cleanup($first_run);
                        return;
                    }
                    push(@targets, $targ->getValue());
                    $self->debug(5, "MULTI resource: $moptname.targets=@targets");
                }
                # quote metachars in each target *before* assembling the line
                my @re_qmtok = ();
                push(@re_qmtok, quotemeta($_)) for(@targets);
                my $re = join('\s+', @re_qmtok);
                $self->debug(5, "re: $re");
                # This is context-dependant: future enhancements should manage it
                NCM::Check::lines($squidCTmpFilePath,
                        linere => '\W*\s*'.$moptname.'\s+'.$name.'\s+'.$type.'\s+.+',
                        goodre => '\s*'.$moptname.'\s+'.$name.'\s+'.$type.'\s+'.$re,
                        good   => "$moptname $name $type @targets",
                        keep   => 'first',
                        add    => 'last'
                    );
            }
        } elsif($moptname eq 'cache_dir') {
            while($mce->hasNextElement()) {
                my $cache_dir = $mce->getNextElement();
                my %entry = $cache_dir->getHash();

                my $property = $entry{type};
                unless(defined($property)) {
                    $self->error("undefined type for cache_dir");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("type is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $type = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.type=$type");

                $property = $entry{directory};
                unless(defined($property)) {
                    $self->error("undefined directory for cache_dir");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("directory is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $directory = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.directory=$directory");

                $property = $entry{MBsize};
                unless(defined($property)) {
                    $self->error("undefined MBsize for cache_dir");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("MBsize is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $MBsize = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.MBsize=$MBsize");

                $property = $entry{level1};
                unless(defined($property)) {
                    $self->error("undefined level1 for cache_dir");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("level1 is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $level1 = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.level1=$level1");

                $property = $entry{level2};
                unless(defined($property)) {
                    $self->error("undefined level2 for cache_dir");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("level2 is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $level2 = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.level2=$level2");

                # This is not context-dependant.
                NCM::Check::lines($squidCTmpFilePath,
                        linere => '\W*\s*'.$moptname.'\s+'.$type.'\s+'.quotemeta($directory).'\s+.+',
                        goodre => '\s*'.$moptname.'\s+'.$type.'\s+'.quotemeta($directory).'\s+'.$MBsize.'\s+'.$level1.'\s+'.$level2,
                        good   => "$moptname $type $directory $MBsize $level1 $level2",
                        keep   => 'first',
                        add    => 'last'
                    );
            }
        } elsif($moptname eq 'http_access') {
            while($mce->hasNextElement()) {
                my $http_access = $mce->getNextElement();
                my %entry = $http_access->getHash();

                my $property = $entry{policy};
                unless(defined($property)) {
                    $self->error("undefined policy for http_access");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("policy is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $policy = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.policy=$policy");

                # more acls might be provided
                my $resource = $entry{acls};
                unless(defined($resource)) {
                    $self->error("undefined acls for http_access");
                    $self->cleanup($first_run);
                    return;
                }
                unless($resource->isResource()) {
                    $self->error("acls is not a resource");
                    $self->cleanup($first_run);
                    return;
                }
                my @acls = ();
                while($resource->hasNextElement()) {
                    my $acl = $resource->getNextElement();
                    unless($acl->isProperty()) {
                        $self->error("acl is not a property");
                        $self->cleanup($first_run);
                        return;
                    }
                    push(@acls, $acl->getValue());
                    $self->debug(5, "MULTI resource: $moptname.acls=@acls");
                }
                # quote metachars in each target *before* assembling the line
                my @re_qmtok = ();
                push(@re_qmtok, quotemeta($_)) for(@acls);
                my $re = join('\s+', @re_qmtok);
                $self->debug(5, "re: $re");
                # This is context-dependant: future enhancements should manage
                # it. Also it is important to match *all* the new directive!
                NCM::Check::lines($squidCTmpFilePath,
                        linere => '\W*\s*'.$moptname.'\s+'.$policy.'\s+'.$re,
                        goodre => '\s*'.$moptname.'\s+'.$policy.'\s+'.$re,
                        good   => "$moptname $policy @acls",
                        keep   => 'first',
                        add    => 'last'
                    );
            }
        } elsif($moptname eq 'refresh_pattern') {
            # TODO: these directives need at least a minimal control on their
            # position! In particular, the 'refresh_pattern . blah-blah' must be
            # the last one!
            while($mce->hasNextElement()) {
                my $refresh_pattern = $mce->getNextElement();
                my %entry = $refresh_pattern->getHash();

                my $property = $entry{pattern};
                unless(defined($property)) {
                    $self->error("undefined pattern for refresh_pattern");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("pattern is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $pattern = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.pattern=$pattern");

                $property = $entry{min};
                unless(defined($property)) {
                    $self->error("undefined min for refresh_pattern");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("min is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $min = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.min=$min");

                $property = $entry{percent};
                unless(defined($property)) {
                    $self->error("undefined percent for refresh_pattern");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("percent is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $percent = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.percent=$percent");

                $property = $entry{max};
                unless(defined($property)) {
                    $self->error("undefined max for refresh_pattern");
                    $self->cleanup($first_run);
                    return;
                }
                unless($property->isProperty()) {
                    $self->error("max is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                my $max = $property->getValue();
                $self->debug(5, "MULTI resource: $moptname.max=$max");

                # This is context-dependant.
                # Comment the default refresh pattern, add the requested line,
                # then add it back as the last one. This is a kludge, and should
                # change once we have context-dependant placement functions...
                my @re_qmtok = ();
                push(@re_qmtok, quotemeta($_)) for(split(' ', 'refresh_pattern . 0 20% 4320'));
                my $re = join('\s+', @re_qmtok);
                $self->debug(5, "re: $re");
                NCM::Check::lines($squidCTmpFilePath,
                        linere => '\W*\s*'.$re,
                        goodre => '\#+\s*'.$re,
                        good   => '#refresh_pattern . 0 20% 4320',
                        keep   => 'first',
                        add    => 'last'
                    );
                NCM::Check::lines($squidCTmpFilePath,
                        linere => '\W*\s*'.$moptname.'\s+'.$pattern.'\s+.+',
                        goodre => '\s*'.$moptname.'\s+'.$pattern.'\s+'.$min.'\s+'.$percent.'\s+'.$max,
                        good   => "$moptname $pattern $min $percent $max",
                        keep   => 'first',
                        add    => 'last'
                    );
                NCM::Check::lines($squidCTmpFilePath,
                        linere => '\s*'.$re,
                        goodre => $re,
                        good   => 'refresh_pattern . 0 20% 4320',
                        keep   => 'first',
                        add    => 'last'
                    );
            }
        } else {
            # try to assign the tokens as a space-separated list of values
            $self->warn("'$moptname': handling as a generic list");
            my @servers = ();
            while($mce->hasNextElement()) {
                my $serv = $mce->getNextElement();
                unless($serv->isProperty()) {
                    $self->error("server is not a property");
                    $self->cleanup($first_run);
                    return;
                }
                push(@servers, $serv->getValue());
                $self->debug(5, "MULTI resource: $moptname.servers=@servers");
                # quote metachars in each target *before* assembling the line
                my @re_qmtok = ();
                push(@re_qmtok, quotemeta($_)) for(@servers);
                my $re = join('\s+', @re_qmtok);
                $self->debug(5, "re: $re");
                NCM::Check::lines($squidCTmpFilePath,
                        linere => '\W*\s*'.$moptname.'\s+.+',
                        goodre => '\s*'.$moptname.'\s+'.$re,
                        good   => "$moptname @servers",
                        keep   => 'first',
                        add    => 'last'
                    );
            }
        }
    }


    ############################################################################
    # Finalization.

    # No configuration backup is made here, since that should have been done
    # at the first component run.
    $reload = differ($squidCTmpFilePath, $squidConfFilePath);
    unless(defined($reload)) {
        $self->error("cannot compare files");
        $self->cleanup($first_run);
        return;
    }
    if($reload) {
        # first check that the new config is good
	CAF::Process->new([qw(/usr/sbin/squid -k parse -f), $squidCTmpFilePath],
			  log => $self)->run();
	if ($?) {
            $self->error("Wrong config file: $squidCTmpFilePath");
            $self->cleanup($first_run);
            return;
        }

        # get current and new swap configurations
        %new_swaps = &get_swap_config($self, $squidCTmpFilePath, 0);
        if($new_swaps{'_ERROR_'}) {
            $self->error("cannot get new swap configuration");
            $self->cleanup($first_run);
            return;
        }
        %current_swaps = &get_swap_config($self, $squidConfFilePath, 1);
        if($current_swaps{'_ERROR_'}) {
            $self->error("cannot get current swap configuration");
            $self->cleanup($first_run);
            return;
        }
        # since the default swap is implicitly pre-configured, add it if missing
        $current_swaps{$squidDefSwapDir} = $squidDefSwapPar
            unless($current_swaps{$squidDefSwapDir});
        $new_swaps{$squidDefSwapDir} = $squidDefSwapPar
            unless(%new_swaps);
        $self->debug(5, "current swaps: ".join(' ', keys(%current_swaps)));
        $self->debug(5, "new swaps    : ".join(' ', keys(%new_swaps)));
        # ...compare new and current sets and erase the common tuples
        if(%current_swaps) {
            for(keys(%new_swaps)) {
                if(defined($current_swaps{$_}) and
                   ($current_swaps{$_} eq $new_swaps{$_})) {
                    # no changes on this swap directive
                    delete($current_swaps{$_});
                    delete($new_swaps{$_});
                }
            }
        }

        # now 'new_swaps' holds swaps to be created anew, and those to be
        # deleted are in 'current_swaps'.
        if(%current_swaps or %new_swaps) {
            # the service must be stopped!
            unless($is_stopped) {
                # squid is running
		CAF::Process->new([qw(/sbin/service squid stop)],
				  log => $self)->run();
		if ($?) {
                    $self->error("Failed to stop Squid");
                    $self->cleanup($first_run);
                    return;
                }
		$is_stopped = 1;
            }
            # reconfigure swaps
            my $dir = '';
            for $dir (keys(%current_swaps)) {
                unless(destroy($dir)) {
                    # this is not critical
                    $self->warn("cannot remove swap $dir");
                }
                $self->info("swap $dir [$current_swaps{$dir}] removed");
            }
            for $dir (keys(%new_swaps)) {
                unless(makedir($dir, 0750)) {
                    $self->error("cannot make swap $dir");
                    $self->cleanup($first_run);
                    return;
                }
                unless(chown($squid_uid, $squid_gid, $dir)) {
                    $self->error("cannot chown swap $dir");
                    $self->cleanup($first_run);
                    return;
                }
            $self->info("swap $dir [$new_swaps{$dir}] created");
            }
            # rebuild actually the swap structure
	    my $cmdres = CAF::Process->new([qw(/usr/sbin/squid -z -f),
					    $squidCTmpFilePath],
					   log => $self)->output();
            chomp($cmdres);
            $self->verbose("$cmdres");
            if($? || $cmdres =~ /FATAL/) {
                $self->error("Failed to rebuild Squid swap structure");
                $self->cleanup($first_run);
                return;
            }
        }

        # ok, install new config
        $self->debug(5, "installing new config");
        unless(copy($squidCTmpFilePath, $squidConfFilePath)) {
            $self->error("cannot install $squidConfFilePath");
            $self->cleanup($first_run);
            return;
        }

        # service re-loading/starting here
	CAF::Process->new(['/sbin/service squid',
			   $is_stopped ? 'start' : 'reload'])->run();
	if ($?) {
            $self->error("Failed to reload Squid with the new configuration");
            $self->cleanup($first_run);
            return;
        }
    }

    unless($self->cleanup(0)) {
        $self->warn("cleanup failed");
    }

    return;
}


##########################################################################
sub Unconfigure {
##########################################################################
    my ($self, $config)=@_;

    # Restore the configuration existing *before* the first component run.

    my %current_swaps = ();
    my %old_swaps = ();
    my $reload = 0;

    my $cmd;

    # proceed only if the signature file is in place
    return 1 unless -e $squidSignFilePath;
    # check if squid is running
    CAF::Process->new([qw(/sbin/service squid status)],
		      log => $self)->run();
    if ($?) {
	$self->error("Failed to query squid status");
	return;
    }
    my $is_stopped = $?;
    # get the original running status
    my $sigf_contents = file_contents($squidSignFilePath);
    unless(defined($sigf_contents)) {
	$self->error("cannot read $squidSignFilePath");
	return;
    }
    my $was_stopped = '';
    for(split(/\n/, $sigf_contents)) {
	if(/^\s*WAS_STOPPED\s*=\s*(\d+)/) {
	    $was_stopped = $1 if(defined($1));
	    last;
	}
    }
    if($was_stopped eq '') {
	$self->error("missing/wrong WAS_STOPPED line in signature file $squidSignFilePath");
	return;
    }

    # Get literal u/gid for the squid user
    my ($squid_uid, $squid_gid) = (getpwnam($squid_user))[2, 3];
    unless(defined($squid_uid) and defined($squid_gid)) {
	$self->error("cannot get 'squid' uid/gid");
	return;
    }
    $self->debug(5, "squid_uid = $squid_uid, squid_gid = $squid_gid");

    # check original and current configs
    $reload = differ($squidCBakFilePath, $squidConfFilePath);
    unless(defined($reload)) {
	$self->error("cannot compare files");
	return;
    }
    $self->debug(5, "reload=$reload, is_stopped=$is_stopped, was_stopped=$was_stopped");

    # get current and old swap configurations
    %current_swaps = &get_swap_config($self, $squidConfFilePath, 1);
    if($current_swaps{'_ERROR_'}) {
	$self->error("cannot get current swap configuration");
	return;
    }
    %old_swaps = &get_swap_config($self, $squidCBakFilePath, 0);
    if($old_swaps{'_ERROR_'}) {
	$self->error("cannot get new swap configuration");
	return;
    }

    # ...since squid insists in looking for its default swap dir, be sure it
    # is re-built
    $old_swaps{$squidDefSwapDir} = $squidDefSwapPar
	unless($old_swaps{$squidDefSwapDir});
    $current_swaps{$squidDefSwapDir} = $squidDefSwapPar
	unless(%current_swaps);
    $self->debug(5, "current swaps: ".join(' ', keys(%current_swaps)));
    $self->debug(5, "old swaps    : ".join(' ', keys(%old_swaps)));
    # ...compare old and current sets and erase the common tuples
    if(%current_swaps) {
	for(keys(%old_swaps)) {
	    if(defined($current_swaps{$_}) and
		   ($current_swaps{$_} eq $old_swaps{$_})) {
		# no changes on this swap directive
		delete($current_swaps{$_});
		delete($old_swaps{$_});
	    }
	}
    }

    # now 'old_swaps' holds swaps to be re-created, and those to be deleted
    # are in 'current_swaps'.
    if(%current_swaps or %old_swaps) {
	# the service must be stopped!
	unless($is_stopped) {
	    # squid is running
	    CAF::Process->new([qw(/sbin/service squid stop)],
			      log => $self)->run();
	    if ($?) {
		$self->error("Failed to stop squid");
		return;
	    }
	    # need a check on $? here???
	    $is_stopped = 1;
	}
	# reconfigure swaps
	my $dir = '';
	for $dir (keys(%current_swaps)) {
	    unless(destroy($dir)) {
		# this is not critical
		$self->warn("cannot remove swap $dir");
	    }
	    $self->info("swap $dir [$current_swaps{$dir}] removed");
	}
	for $dir (keys(%old_swaps)) {
	    unless(makedir($dir, 0750)) {
		$self->error("cannot make swap $dir");
		return;
	    }
	    unless(chown($squid_uid, $squid_gid, $dir)) {
		$self->error("cannot chown swap $dir");
		return;
	    }
	    $self->info("swap $dir [$old_swaps{$dir}] created");
	}
	# rebuild actually the swap structure
	my $cmdres = CAF::Process->new([qw(/usr/sbin/squid -z -f),
					$squidCBakFilePath],
				       log =>$self)->output();
	chomp($cmdres);
	$self->verbose("$cmdres");
	if($? || $cmdres =~ /FATAL/) {
	    $self->error("command $cmd failed");
	    return;
	}
	$reload = 1;
	# actual restart is performed after having restored the original
	# config...
    }

    # restore the original config
    unless($self->cleanup(1)) {
	$self->error("cleanup failed");
	return;
    }
    $self->debug(5, "reload=$reload, is_stopped=$is_stopped, was_stopped=$was_stopped");
    if($reload) {
	# restart the service only if it was originally running
	unless($was_stopped) {
	    $cmd = CAF::Process->new(['/sbin/service squid',
				      ($is_stopped ? 'start' : 'reload')],
				     log => $self);
	}
	elsif(!$is_stopped) {
	    $cmd = CAF::Process->new([qw(/sbin/service squid stop)],
				     log => $self);
	}
        elsif($was_stopped and !$is_stopped) {
	    $cmd = CAF::Process->new([qw(/sbin/service squid stop)],
				     log => $self);
        }
        # run the command
	if($cmd) {
	    $cmd->run();
	    if ($?) {
		$self->error("Failed to restart or stop the service");
		return;
	    }
	}
    }
    return;
}


1; #required for Perl modules
