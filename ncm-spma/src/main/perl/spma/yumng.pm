# #
# Software subject to following license(s):
#   Apache 2 License (http://www.opensource.org/licenses/apache2.0)
#   Copyright (c) Responsible Organization
#

# #
# Current developer(s):
#   Jindrich Novy <jindrich.novy@morganstanley.com>
#

# #
# Author(s): Jindrich Novy
#

package NCM::Component::spma::yumng;

#
# a few standard statements, mandatory for all components
#
use strict;
use warnings;
use NCM::Component;
our $EC  = LC::Exception::Context->new->will_store_all;
our @ISA = qw(NCM::Component);
use EDG::WP4::CCM::Element qw(unescape);

use CAF::Process;
use CAF::FileWriter;
use Set::Scalar;
use File::Path qw(mkpath rmtree);
use LWP::Simple;
use Text::Glob qw(match_glob);

use constant HOSTNAME            => "/system/network/hostname";
use constant DOMAINNAME          => "/system/network/domainname";
use constant REPOS_DIR           => "/etc/yum.repos.d";
use constant REPOS_TREE          => "/software/repositories";
use constant PKGS_TREE           => "/software/packages";
use constant GROUPS_TREE         => "/software/groups/names";
use constant CMP_TREE            => "/software/components/spma";
use constant YUM_PACKAGE_LIST    => "/etc/yum/pluginconf.d/versionlock.list";
use constant YUM_CONF_FILE       => "/etc/yum.conf";
use constant RPM_QUERY_INSTALLED => qw(rpm -qa --nosignature --nodigest --qf %{EPOCH}:%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n);
use constant REPO_AVAIL_PKGS     => qw(repoquery -C --show-duplicates --all --qf %{EPOCH}:%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH});
use constant YUM_PLUGIN_OPTS	 => "--disableplugin=\* --enableplugin=fastestmirror --enableplugin=versionlock";
use constant YUM_TEST_CHROOT     => qw(/tmp/spma_yum_testroot);
use constant SPMA                => "/software/components/spma";
use constant SPMAPROXY           => "/software/components/spma/proxy";

our $NoActionSupported = 1;

# If user packages are not allowed, removes any repositories present
# in the system that are not listed in $allowed_repos.
sub cleanup_old_repos
{
    my ( $self, $repo_dir, $allowed_repos, $allow_user_pkgs ) = @_;

    return 1 if $allow_user_pkgs;

    my $dir;
    if ( !opendir( $dir, $repo_dir ) ) {
        $self->error("Unable to read repositories in $repo_dir");
        return 0;
    }

    my $current = Set::Scalar->new( map( m{(.*)\.repo$}, readdir($dir) ) );

    closedir($dir);
    my $allowed = Set::Scalar->new( map( $_->{name}, @$allowed_repos ) );
    my $rm = $current - $allowed;
    foreach my $i (@$rm) {
        # We use $f here to make Devel::Cover happy
        my $f = "$repo_dir/$i.repo";
        $self->verbose("Unlinking outdated repository $f");
        if ( !unlink($f) ) {
            $self->error("Unable to remove outdated repository $i: $!");
            return 0;
        }
    }
    return 1;
}

=pod

=head2 C<execute_yum_command>

Executes C<$command> for reason C<$why>. Optionally with standard
input C<$stdin>.  The command may be executed even under --noaction if
C<$keeps_state> has a true value.

If the command is executed, this method returns its standard output
upon success or C<undef> in case of error.  If the command is not
executed the method always returns a true value (usually 1, but don't
rely on this!).

Yum-based commands require annoying error handling: they may exit 0
even upon errors.  In those cases, we have to detect errors by looking
at stderr.  This method just encapsulates all that logic, keeping the
callers clean.

=cut

my $yum_warned;
my $yum_error;

sub execute_yum_command
{
    my ( $self, $command, $why, $keeps_state, $stdin, $error_logger, $error_ok ) = @_;

    $error_logger = "error" if ( !( $error_logger && $error_logger =~ m/^(error|warn|info|verbose)$/ ) );

    $yum_warned = 0;

    my ( %opts, $out, $err, @missing );

    %opts = ( log => $self,
        stdout      => \$out,
        stderr      => \$err,
        keeps_state => $keeps_state );

    $opts{stdin} = $stdin if defined($stdin);

    my $cmd = CAF::Process->new( $command, %opts );

    $cmd->info("$why");
    $cmd->execute();
    $yum_error = $err;
    if ( $err && ( !defined($error_ok) || $error_ok != 1 ) ) {
        $self->warn("$why produced warnings: $err") if ( $err && ( !defined($error_ok) || $error_ok != 1 ) );
        $yum_warned = 1;
    }
    $self->verbose("$why output:\n$out") if ( defined($out) );
    if ( $? ||
        ( $err && $err =~ m{^(?:Error|Failed|
                      (?:Could \s+ not \s+ match)|
                      (?:Transaction \s+.*rror)|
                      (?:Unknown \s+ group \s+  package \s+ type) |
                      (?:.*requested \s+ URL \s+ returned \s+ error))}oxmi ) ||
        ( $out && ( @missing = ( $out =~ m{^No package (.*) available}omg ) ) )
      ) {
        return undef if ( !defined($error_ok) || $error_ok != 1 );
        $self->$error_logger( "Failed $why: ", $err || "(empty/undef stderr)" );
        if (@missing) {
            $self->$error_logger( "Missing packages: ", join ( " ", @missing ) );
        }
        return $err;
    }
    return $cmd->{NoAction} || $out;
}

sub execute_yum_command_with_recovery
{
    my ( $self, $command, $why, $keeps_state, $stdin, $error_logger, $error_ok ) = @_;
    my $status = $self->execute_yum_command($command, $why, $keeps_state, $stdin, $error_logger, $error_ok);
    my $packages_modified = 0;

    if ( !defined($status) ) {
	my @lines = split /\n/, $yum_error;
	foreach my $line (@lines) {
	    my $cf = index($line, 'conflicts with file from package');
	    if ( $cf != -1) {
		my $pkg = $line;
		$pkg =~ s,^.*package ,,;
		$pkg =~ s,-[0-9]*:,-,;
		$self->execute_yum_command(["rpm -e --nodeps $pkg"], "removing $pkg to avoid file conflict");
		$packages_modified = 1;
	    }
	}
	if ( $packages_modified ) {
	    $status = $self->execute_yum_command($command, 'retrying: '.$why, $keeps_state, $stdin, $error_logger, $error_ok);
	}
    }
    return $status;
}

sub Configure
{
    my ( $self, $config ) = @_;

    # Make sure stdout and stderr is flushed every time to not to
    # put mess on serial console
    autoflush STDOUT 1;
    autoflush STDERR 1;

    # We are parsing some outputs in this component. We must set a
    # locale that we can understand.
    local $ENV{LANG}   = 'C';
    local $ENV{LC_ALL} = 'C';

    my $repos = $config->getElement(REPOS_TREE)->getTree();
    my $t     = $config->getElement(CMP_TREE)->getTree();
    
    # Display system info
    if ( defined($t->{quattor_os_release}) ) {
	$self->info("target OS build: ", $t->{quattor_os_release});
    }
    
    my $spmaver = $self->execute_yum_command( ["rpm -q --qf %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH} ncm-spma"], "checking for spma version", 1);
    $self->info("SPMA version: ", $spmaver);
    $self->info("User packages permitted: $t->{userpkgs}");

    # Convert these crappily-defined fields into real Perl booleans.
    $t->{run}      = $t->{run} eq 'yes';
    $t->{userpkgs} = defined( $t->{userpkgs} ) && $t->{userpkgs} eq 'yes';

    # test for sharp spma execution early
    my $spma_run = 0;
    if ( -e "/.spma-run" ) {
        if ( !unlink "/.spma-run" ) {
            $self->warn("unable to remove file /.spma-run: $!");
        }
	$spma_run = 1;
    }

    # Detect legacy OS (RHEL5 and older)
    my $legacy_os = 0;
    my $fhi;
    if ( open( $fhi, '<', "/etc/redhat-release" ) ) {
        while ( my $line = <$fhi> ) {
            if ( index( $line, 'release 5' ) >= 0 ) {
                $legacy_os = 1;
                last;
            }
        }
        $fhi->close();
    } else {
        $self->warn("Unable to determine OS release.");
    }

    # Generate YUM config file
    my $yum_conf_file = CAF::FileWriter->new( YUM_CONF_FILE, log => $self );
    my $excludes      = $t->{excludes};
    print $yum_conf_file $t->{yumconf};
    print $yum_conf_file "exclude=" . join ( " ", sort @$excludes );
    $yum_conf_file->close();

    if ( !$NoAction ) {
        # Remove all repositories if userpkgs is not defined
        $self->cleanup_old_repos( REPOS_DIR, $repos, $t->{userpkgs} ) or return 0;
    }

    # Generate new installation repositories from host profile
    my $proxy = !defined($t->{proxy}) ? 'yes' : $t->{proxy};
    foreach my $repo (@$repos) {
        my $fh = CAF::FileWriter->new( REPOS_DIR . "/spma-$repo->{name}.repo", log => $self );
        my $prots = $repo->{protocols}->[0];
        my $url   = $prots->{url};
        my $urls;
        my $repo_proxy = defined($repo->{proxy}) ? 'yes' : 'no';
        my $disable_proxy = defined($repo->{disableproxy}) ? 'yes' : 'no';
        if ( $url =~ /http/ && $proxy eq 'yes' && $disable_proxy eq 'no' ) {
            if ( $config->elementExists(SPMAPROXY) ) {
                my $spma       = $config->getElement(SPMA)->getTree;
                my $proxyhost = $spma->{proxyhost};
                my $proxyport;
                my @proxies    = split /,/, $proxyhost;
                if ( $spma->{proxyport} ) {
                    $proxyport = $spma->{proxyport};
                }
                if ($proxyhost) {
		    if ( $repo_proxy eq 'no' ) {
			while (@proxies) {
			    my $prx = shift(@proxies);
			    $prx .= ":$proxyport" if $spma->{proxyport};
			    $url =~ s{(https?)://([^/]*)/}{$1://$prx/};
			    $urls .= $url . ' ';
			}
		    } else {
			$url .= ":$proxyport" if $spma->{proxyport};
			$url =~ s,http?://,,;
			$url =~ s,[^/]*/,,;
			$url = $repo->{proxy} . $url;
		    }
		}
	    }
	}
	if (!defined($urls)) {
	    $urls = $url;
	}
        my $repofile = "[$repo->{name}]\nname=$repo->{name}\nbaseurl=$urls\nenabled=$repo->{enabled}\ngpgcheck=$repo->{gpgcheck}\n";
        if ( defined( $repo->{mirrorlist} ) && $repo->{mirrorlist} ) {
            $repofile = "[$repo->{name}]\nname=$repo->{name}\nmirrorlist=$url\nenabled=$repo->{enabled}\ngpgcheck=$repo->{gpgcheck}\n";
        }
        print $fh "# File generated by ", __PACKAGE__, ". Do not edit\n";
        print $fh $repofile;
        $fh->close();
    }

    # Preprocess required packages and separate version-locked
    #    - also skip package dualities - e.g. both kernel and kernel-2.6.32-504.1.3.el6.x86_64
    #      specified on yum install commandline will skip older version-locked package but
    #      will install the latest what is undesired. Simply keep only version-locked variant.
    my $pkgs               = $config->getElement(PKGS_TREE)->getTree();
    my $wanted_pkgs        = Set::Scalar->new();
    my $wanted_pkgs_locked = Set::Scalar->new();
    my $found_spma         = 0;
    my @pkl;
    my @pkl_v;
    my @pkl_a;

    for my $name ( keys %$pkgs ) {
        if ( !$found_spma && substr( unescape $name, 0, 8 ) eq 'ncm-spma' ) {
            $found_spma = 1;
        }
        my $vra = $pkgs->{$name};
        while ( my ( $vers, $a ) = each(%$vra) ) {
            my $arches = $a->{arch};
            if ( exists( $a->{repository} ) ) {
                foreach my $arch (@$arches) {
                    if ( $vers ne '_' ) {
                        push ( @pkl_v, ( unescape $name) . ';' . ( unescape $vers) . '.' . $arch );
                    } else {
                        if ( $arch eq '_' ) {
                            push ( @pkl, unescape $name . ';' );
                        } else {
                            push ( @pkl_a, unescape $name . ';' . $arch );
                        }
                    }
                }
            } else {
                foreach my $arch ( keys %$arches ) {
                    if ( $vers ne '_' ) {
                        push ( @pkl_v, ( unescape $name) . ';' . ( unescape $vers) . '.' . $arch );
                    } else {
                        if ( $arch eq '_' ) {
                            push ( @pkl, unescape $name . ';' );
                        } else {
                            push ( @pkl_a, unescape $name . ';' . $arch );
                        }
                    }
                }
            }
        }
    }

    if ( !$found_spma ) {
        $self->error('Package ncm-spma is not present among required packages.');
        return 0;
    }

    my $wanted_pkgs_uv = Set::Scalar->new(@pkl);
    my $wanted_pkgs_v  = Set::Scalar->new(@pkl_v);
    my $wanted_pkgs_a  = Set::Scalar->new(@pkl_a);
    while ( defined( my $p = $wanted_pkgs_uv->each ) ) {
        while ( defined( my $p2 = $wanted_pkgs_v->each ) ) {
            if ( index( $p2, $p ) == 0 ) {
                my $pkg = $p;
                chop($pkg);
                my $pkg_locked = $p2;
                $pkg_locked =~ tr/;/-/;
                $self->info("preferring version-locked $pkg_locked over unlocked $pkg");
                $wanted_pkgs_uv->delete($p);
            }
        }
    }
    while ( defined( my $p = $wanted_pkgs_uv->each ) ) {
        chop($p);
        $wanted_pkgs->insert($p);
    }
    while ( defined( my $p = $wanted_pkgs_v->each ) ) {
        $p =~ s/;/-/;
        $wanted_pkgs_locked->insert($p);
    }
    while ( defined( my $p = $wanted_pkgs_a->each ) ) {
        $p =~ s/;/./;
        $wanted_pkgs->insert($p);
    }

    if ( !$NoAction ) {
        # Import GPG keys
        foreach my $file ( glob "/etc/pki/rpm-gpg/RPM-GPG-KEY*" ) {
            my $gpg = $self->execute_yum_command( ["rpm -v --import $file"], "importing GPG key $file" );
            return 0 if !defined($gpg);
        }
    }

    # Get list of packages installed on system before any package modifications.
    my $preinstalled_rpms = $self->execute_yum_command( [RPM_QUERY_INSTALLED], "getting list of installed packages", 1 );
    return 0 if !defined($preinstalled_rpms);
    $preinstalled_rpms =~ s/\(none\)/0/g;
    my $preinstalled = Set::Scalar->new( split ( /\n/, $preinstalled_rpms ) );

    if ( !$NoAction && $spma_run ) {
	# Attempt to update YUM and plugins to latest available release.
	my $updateyum = $self->execute_yum_command( ["yum update -y yum\* " . YUM_PLUGIN_OPTS], "updating YUM stack" );
	if ($yum_warned) {
	    # Be sure to use current version of YUM available in metadata (should handle downgrades).
	    my $yum_reinstall = $self->execute_yum_command( ["yum reinstall -y yum\* " . YUM_PLUGIN_OPTS], "making sure we are using correct YUM" );
	    # Expiration of cache is not enough sometimes.
	    # https://bugzilla.redhat.com/show_bug.cgi?id=1151074
	    my $yum_clean = $self->execute_yum_command( ["yum clean all " . YUM_PLUGIN_OPTS], "resetting hard YUM state" );
	    return 0 if !defined($yum_clean);
	}
    }

    # Clean up YUM state - worth to be thorough there
    my $yum_clean = $self->execute_yum_command( ["yum clean expire-cache " . YUM_PLUGIN_OPTS], "expiring YUM caches", 1 );
    if ($yum_warned) {
        # Expiration of cache is not enough sometimes.
        # https://bugzilla.redhat.com/show_bug.cgi?id=1151074
        my $yum_clean = $self->execute_yum_command( ["yum clean all " . YUM_PLUGIN_OPTS], "resetting hard YUM state", 1 );
        return 0 if !defined($yum_clean);
    }

    return 0 if !defined($yum_clean);
    $yum_clean = $self->execute_yum_command( ["yum makecache " . YUM_PLUGIN_OPTS], "generating YUM cache", 1 );
    return 0 if !defined($yum_clean);

    my @files = glob "{/tmp/*.yumtx,/var/lib/yum/transaction*}";
    foreach my $file (@files) {
        if ( !unlink $file ) {
            $self->info("unable to remove file $file: $!");
        }
    }
    my @dirs = glob "/var/tmp/yum-root*";
    foreach my $dir (@dirs) {
        if ( !rmtree $dir) {
            $self->info("unable to remove directory $dir: $!");
        }
    }

    # Test whether comps/groups are sane.
    {
	$yum_warned = 0;
	my $groupinfo = $self->execute_yum_command( [ "yum groupinfo core " . YUM_PLUGIN_OPTS ], "testing comps/groups sanity", 1 );
	if ( $yum_warned ) {
	    $self->error("Groups are not sane - core group missing. Will not continue.");
	    return 0;
	}
    }

    # Query metadata for version locked packages including Epoch and write versionlock.list
    my $repodata_rpms = $self->execute_yum_command( [REPO_AVAIL_PKGS], "fetching full package list", 1 );
    return 0 if !defined($repodata_rpms);

    # Test whether locked packages are present in the metadata
    my $repoquery_list = Set::Scalar->new( reverse(split ( /\n/, $repodata_rpms)) );
    my $repoquery_list_noepoch = Set::Scalar->new();
    my $locked_found           = Set::Scalar->new();
    my $locked_found_noepoch   = Set::Scalar->new();
    $self->info( "(" . $repoquery_list->size . " total packages)" );
    while ( defined( my $p = $repoquery_list->each ) ) {
        my $t = $p;
        $t =~ s/^.*://;
        if ( !$repoquery_list_noepoch->has($t) ) { $repoquery_list_noepoch->insert($t); }
        if ( $wanted_pkgs_locked->has($t) ) {
            if ( !$locked_found->has($p) ) {
                $self->verbose("Found package $p");
                $locked_found->insert($p);
                $locked_found_noepoch->insert($t);
            }
        }
    }
    {
        my $fh = CAF::FileWriter->new( YUM_PACKAGE_LIST, log => $self );
        print $fh join ( "\n", @$locked_found );
        $fh->close();
        if ( $wanted_pkgs_locked->size != $locked_found->size ) {
            $self->error( "Version-locked packages are missing from repositories - expected ", $wanted_pkgs_locked->size, ", available ", $locked_found->size );
            $self->error( "Missing packages: ", $wanted_pkgs_locked - $locked_found_noepoch );
            return 0;
        } else {
            $self->info("all version locked packages available in repositories");
        }
    }

    # Test also whether version unlocked packages are present in repositories.
    {
	my $found = Set::Scalar->new();
	while ( defined( my $r = $repoquery_list->each ) ) {
	    my $t = $r;
	    $t =~ s/^.*://;
	    my $name = $t;
	    my $arch = substr($name, rindex($t, '.'));
	    while( (my $end = rindex($name, '-')) != -1) {
		$name = substr($t, 0, $end);
		if ( $wanted_pkgs->has("$name$arch") ) {
		    $found->insert("$name$arch");
		    last;
		}
		if ( $wanted_pkgs->has("$name") ) {
		    $found->insert("$name");
		    last;
		}
	    }
	}
	if ( $found->size != $wanted_pkgs->size ) {
            $self->error("Requested packages are missing from repositories.");
	    $self->error("Missing packages: ", $wanted_pkgs - $found);
	    return 0;
	}
    }

    # Continue only if package content is supposed to be changed
    if ( !$spma_run ) {
        return 1 if !$t->{run};
    }

    # Run test transaction to get complete list of packages to be present on the system
    my $groups	   = $config->getElement(GROUPS_TREE)->getTree();
    my $clean_root = $self->execute_yum_command( [ "rm -rf " . YUM_TEST_CHROOT ], "cleaning YUM test chroot", 1 );
    $clean_root = $self->execute_yum_command( [ "mkdir -p " . YUM_TEST_CHROOT . "/var/cache" ],                 "setting up YUM test chroot",    1 );
    $clean_root = $self->execute_yum_command( [ "ln -s /var/cache/yum " . YUM_TEST_CHROOT . "/var/cache/yum" ], "setting YUM test chroot cache", 1 );
    my $yum_install_test_command;
    $yum_install_test_command = "yum install " . YUM_PLUGIN_OPTS . " -q -C --installroot=" . YUM_TEST_CHROOT;
    if (@$groups)             { $yum_install_test_command .= " @" . join   ( " @",   sort @$groups ); }
    if (@$wanted_pkgs_locked) { $yum_install_test_command .= " " . join    ( " ",    sort @$wanted_pkgs_locked ); }
    if (@$wanted_pkgs)        { $yum_install_test_command .= " " . join    ( " ",    sort @$wanted_pkgs ); }
    my $yum_install_test = $self->execute_yum_command( [$yum_install_test_command], "performing YUM chroot install test", 1, "/dev/null", "verbose", 1 );
    $self->log($yum_install_test_command);
    return 0 if !defined($yum_install_test);
    $self->log($yum_install_test);
    my $clean_root_after = $self->execute_yum_command( [ "rm -rf " . YUM_TEST_CHROOT ], "removing YUM test chroot", 1 );

    # Parse YUM output to get full package list
    my $to_install = Set::Scalar->new;
    if ( !$legacy_os ) {
        # RHEL6+ falls here - we don't support anything older than RHEL5 (inclusive)
        my $skipped = index( $yum_install_test, "Skipped (dependency problems):" );
        if ( $skipped != -1 ) {
	    $self->info($yum_install_test);
            $self->error("Dependency problems in test transaction, see log.");
            if ( !defined( $t->{yumtolerant} ) || !( $t->{yumtolerant} eq 'yes' ) ) {
                return 0;
            }
        }
        my @tx_files = glob "/tmp/*.yumtx";
        if ( scalar( grep { defined $_ } @tx_files ) != 1 ) {
	    $self->info($yum_install_test);
            $self->error( "Dependency problems or multiple yumtx files. See log." );
            return 0;
        }
        my $tx_file = $tx_files[0];
        my $fh;
        if ( !open $fh, '<', $tx_file ) {
            $self->error("Unable to open transaction file $tx_file: $!");
            return 0;
        }
        my @lines = grep /^mbr:/, <$fh>;
        foreach (@lines) {
            my ( $epoch, $name, $version, $release, $arch, $rest );
            $_ =~ s/mbr: //;
            ( $name,    $rest ) = split ( /,/, $_,    2 );
            ( $arch,    $rest ) = split ( /,/, $rest, 2 );
            ( $epoch,   $rest ) = split ( /,/, $rest, 2 );
            ( $version, $rest ) = split ( /,/, $rest, 2 );
            ( $release, $rest ) = split ( / /, $rest, 2 );
            $to_install->insert( $epoch . ':' . $name . '-' . $version . '-' . $release . '.' . $arch );
        }
        $fh->close();
    } else {
        # RHEL5 specific - yum lacks yumtx transaction support - parse YUM output directly instead
        my $start_found          = 0;
        my $aftername_wrapped    = 0;
        my $afterversion_wrapped = 0;
        my ( $epoch, $name, $versionrelease, $arch );
        my @lines = split /\n/, $yum_install_test;
        foreach my $l (@lines) {
            if ($afterversion_wrapped) {
                $afterversion_wrapped = 0;
                next;
            }
            if ( $l ne "Installing:" ) {
                next if ( !$start_found );
            } else {
                $start_found = 1;
                next;
            }
            next if ( $l eq "Installing for dependencies:" );
            if ( $l eq "Skipped (dependency problems):" ) {
                my $skipped = index( $yum_install_test, "Skipped (dependency problems):" );
                if ( $skipped != -1 ) {
		    $self->info($yum_install_test);
                    $self->error("Dependency problems in test transaction, see log.");
                    if ( !defined( $t->{yumtolerant} ) || !( $t->{yumtolerant} eq 'yes' ) ) {
                        return 0;
                    }
                }
            }
            last if ( substr( $l, 0, 1 ) ne ' ' );
            next if ( substr( $l, 1, 1 ) eq ' ' && !$aftername_wrapped && !$afterversion_wrapped );
            $l =~ s/^\s+|\s+$//g;
            if ( !$aftername_wrapped ) {
                ( $name, $l ) = split ( / /, $l, 2 );
                if ( !defined($l) || $l eq "" ) {
                    $aftername_wrapped = 1;
                    next;
                }
                $l =~ s/^\s+//;
            } else {
                $aftername_wrapped = 0;
            }
            ( $arch, $l ) = split ( / /, $l, 2 );
            $l =~ s/^\s+//;
            my $eindex = index( $l, ':' );
            if ( $eindex > 0 ) {
                $epoch = substr( $l, 0, $eindex );
                $l = substr( $l, $eindex + 1 );
            } else {
                $epoch = 0;
            }
            ( $versionrelease, $l ) = split ( / /, $l, 2 );
            $to_install->insert( $epoch . ':' . $name . '-' . $versionrelease . '.' . $arch );
            if ( !defined($l) || $l eq "" ) {
                $afterversion_wrapped = 1;
            }
        }
    }
    $self->info( "supposed to be installed: ", $to_install->size, " packages." );
    if ( $to_install->is_empty ) {
        $self->error("YUM failed: no packages to be installed to clean root.");
        return 0;
    }
    if ($NoAction) {
        my $will_remove = $preinstalled - $to_install;
        my $will_install = $to_install - $preinstalled;
        my $whitelist = $t->{whitelist};
	my $whitelisted = Set::Scalar->new();
        for my $rpm ( $will_remove->elements ) {    # do not remove imported GPG keys
            if ( substr( $rpm, 0, 13 ) eq '0:gpg-pubkey-' ) {
                $will_remove->delete($rpm);
            }
            # Do not remove whitelisted packages.
            if ( defined($whitelist) ) {
		for my $white_pkg (@$whitelist) {
		    my $rpm_noepoch = $rpm;
		    $rpm_noepoch =~ s/^.*://;
		    if ( index($rpm_noepoch, $white_pkg) == 0 || match_glob($white_pkg, $rpm_noepoch) ) {
			$will_remove->delete($rpm);
			$whitelisted->insert($rpm);
		    }
		}
	    }
        }
	$self->info("----------------------------------------");
	if ( defined($whitelisted) && scalar @$whitelisted > 0 ) {
	    $self->info( "whitelist ", scalar @$whitelisted, " package(s): ", join ( " ", sort @$whitelisted ) );
	}
	if (@$excludes) {
	    $self->info( "exclude   ", scalar @$excludes, " package(s): ", join ( " ", sort @$excludes ) );
	}
        $self->info( "install   " , $will_install->size, " package(s): ", join ( " ", sort @$will_install ) );
        $self->info( "remove    ", $will_remove->size, " package(s): ", join ( " ", sort @$will_remove ) );
	$self->info("----------------------------------------");
        return 1;
    }

    # Remove packages not present in metadata and not whitelisted ones.
    my $installed = $preinstalled;
    my $installed_rpms = $preinstalled_rpms;
    my $to_remove = $preinstalled - $repoquery_list;
    my $whitelist = $t->{whitelist};
    for my $rpm ( $to_remove->elements ) {    # do not remove imported GPG keys
	if ( substr( $rpm, 0, 13 ) eq '0:gpg-pubkey-' ) {
	    $to_remove->delete($rpm);
	}
	# Do not remove whitelisted packages.
	if ( defined($whitelist) ) {
	    for my $white_pkg (@$whitelist) {
		my $rpm_noepoch = $rpm;
		$rpm_noepoch =~ s/^.*://;
		if ( index($rpm_noepoch, $white_pkg) == 0 || match_glob($white_pkg, $rpm_noepoch) ) {
		    $to_remove->delete($rpm);
		}
	    }
	}
    }
    if ( !$to_remove->is_empty && !$t->{userpkgs} ) {
        my $remove_rpms = $self->execute_yum_command( [ "yum remove -y -C -q " . YUM_PLUGIN_OPTS . " " . join ( " ", sort @$to_remove ) ], "removing unknown package(s)", 0, "/dev/null" );
	$installed_rpms = $self->execute_yum_command( [RPM_QUERY_INSTALLED], "getting list of installed packages" );
	return 0 if !defined($installed_rpms);
	$installed_rpms =~ s/\(none\)/0/g;
	$installed = Set::Scalar->new( split ( /\n/, $installed_rpms ) );
	my $removed = $preinstalled - $installed;
	if ( !$removed->is_empty ) {
	    $self->info("removed " . $removed->size . " unknown package(s): " . $removed );
	}
    }

    # Be sure to downgrade from newer to version locked versions
    my $to_sync = $to_install - $installed;
    if ( !$to_sync->is_empty ) {
        # YUM distro-sync is buggy - use downgrade approach for version locked packages
        # installation will be executed later on
        my $pre = $installed;
        my $downgraded = $self->execute_yum_command_with_recovery( [ "yum downgrade -q -y " . YUM_PLUGIN_OPTS . " " . join ( " ", sort @$to_sync ) ], "downgrading packages", 0, "/dev/null", "error", 1 );
	$installed_rpms = $self->execute_yum_command( [RPM_QUERY_INSTALLED], "getting list of installed packages" );
	return 0 if !defined($installed_rpms);
	$installed_rpms =~ s/\(none\)/0/g;
	$installed = Set::Scalar->new( split ( /\n/, $installed_rpms ) );
	my $downgraded_to = $installed - $pre;
	if ( !$downgraded_to->is_empty ) {
	    $self->info("downgraded ".$downgraded_to->size." package(s) to: ", $downgraded_to);
	}
	$pre = $installed;
	my $updated = $self->execute_yum_command_with_recovery( [ "yum update -q -y " . YUM_PLUGIN_OPTS ], "updating packages" );
	return 0 if ( !defined($updated) );
	$installed_rpms = $self->execute_yum_command( [RPM_QUERY_INSTALLED], "getting list of installed packages" );
	return 0 if !defined($installed_rpms);
	$installed_rpms =~ s/\(none\)/0/g;
	$installed = Set::Scalar->new( split ( /\n/, $installed_rpms ) );
	my $updated_to = $installed - $pre;
	if ( !$updated_to->is_empty ) {
	    $self->info("updated ".$updated_to->size." package(s) to: ", $updated_to);
	}
    } else {
        $self->info("no packages to upgrade/downgrade");
    }

    # Install only additional packages to what is already installed
    my $will_install = $to_install - $installed;
    if ( !$will_install->is_empty ) {
        my $pre = $installed;
        my $install_rpms = $self->execute_yum_command_with_recovery( [ "yum install -y " . YUM_PLUGIN_OPTS . " " . join( " ", sort @$will_install) ], "installing ".$will_install->size." package(s)" );
	$installed_rpms = $self->execute_yum_command( [RPM_QUERY_INSTALLED], "getting list of installed packages" );
	return 0 if !defined($installed_rpms);
	$installed_rpms =~ s/\(none\)/0/g;
	$installed = Set::Scalar->new( split ( /\n/, $installed_rpms ) );
	my $installed_new = $installed - $pre;
	if ( !$installed_new->is_empty ) {
	    $self->info("installed " . $installed_new->size . " package(s): ", $installed_new);
	}
    } else {
        $self->info("nothing to install");
    }

    # Create list of packages to be removed
    my $will_remove = $installed - $to_install;
    my $whitelisted = Set::Scalar->new();
    $whitelist = $t->{whitelist};
    for my $rpm ( $will_remove->elements ) {    # do not remove imported GPG keys
        if ( substr( $rpm, 0, 13 ) eq '0:gpg-pubkey-' ) {
            $will_remove->delete($rpm);
        }
	# Do not remove whitelisted packages.
	if (defined($whitelist)) {
	    for my $white_pkg (@$whitelist) {
		my $rpm_noepoch = $rpm;
		$rpm_noepoch =~ s/^.*://;
		if ( index($rpm_noepoch, $white_pkg) == 0 || match_glob($white_pkg, $rpm_noepoch) ) {
		    $will_remove->delete($rpm);
		    $whitelisted->insert($rpm);
		}
	    }
	}
    }

    # Remove unwanted packages
    if ( !$will_remove->is_empty ) {
        if ( !$t->{userpkgs} || (defined($t->{metadatapkgs}) && $t->{metadatapkgs}) ) {
            while ( defined( my $p = $will_remove->each ) ) {
                if ( substr( $p, 0, 8 ) eq 'ncm-spma' ) {
                    $self->error("Attempting to remove ncm-spma! You seem to miss SELF from /software/packages = {}?");
                    return 0;
                }
            }
	    my $pre = $installed;
            my $remove_rpms = $self->execute_yum_command( [ "yum remove -y -C -q " . YUM_PLUGIN_OPTS . " " . join ( " ", sort @$will_remove ) ], "removing unwanted packages", 0, "/dev/null" );
	    $installed_rpms = $self->execute_yum_command( [RPM_QUERY_INSTALLED], "getting list of installed packages" );
	    return 0 if !defined($installed_rpms);
	    $installed_rpms =~ s/\(none\)/0/g;
	    $installed = Set::Scalar->new( split ( /\n/, $installed_rpms ) );
	    my $removed = $pre - $installed;
	    if ( !$removed->is_empty ) {
		$self->info("removed " . $removed->size . " package(s): ", $removed);
	    }
        } else {
            $self->info( "userpkgs/metadatapkgs enabled, will not remove " . $will_remove->size . " user packages: ", join ( " ", sort @$will_remove ) );
        }
    } else {
        $self->info("nothing to remove");
    }

    # Sign-off successful SPMA installation by generating quattor_os_file.
    if ( defined($t->{quattor_os_file}) && defined($t->{quattor_os_release}) ) {
        my $fh = CAF::FileWriter->new( $t->{quattor_os_file}, log => $self );
        print $fh $t->{quattor_os_release} . "\n";
        $fh->close();
    }

    # Try to print mirror latencies
    if ( -e "/var/cache/yum/timedhosts.txt" ) {
        my $mirror_latencies = $self->execute_yum_command( ["cat /var/cache/yum/timedhosts.txt"], "reading mirror latencies" );
	if ( $mirror_latencies ) {
	    $self->info( "Mirror latencies:\n" . $mirror_latencies );
	}
    }

    # Final statistics of spma changes of packages
    my $newly_installed = $installed - $preinstalled;
    my $newly_removed   = $preinstalled - $installed;
    $self->info("----------------------------------------");
    if ( defined($whitelisted) && scalar @$whitelisted > 0 ) {
	$self->info( "whitelisted " . scalar @$whitelisted . " package(s) ", join ( " ", sort @$whitelisted ) );
    }
    if (@$excludes) {
	$self->info( "excluded    ", scalar @$excludes, " package(s):  ", join ( " ", sort @$excludes ) );
    }
    if ( defined($whitelist) || @$excludes ) {
	$self->info("----------------------------------------");
    };
    $self->info( "installed   " . $newly_installed->size . " package(s) ", join ( " ", sort @$newly_installed ) );
    $self->info( "removed     "  . $newly_removed->size . " package(s) ", join ( " ", sort @$newly_removed ) );
    $self->info("----------------------------------------");

    return 1;
}

1;    # required for Perl modules
