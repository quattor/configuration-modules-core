# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::spma::yumng;

#
# a few standard statements, mandatory for all components
#
use strict;
use warnings;
use NCM::Component;
our $EC  = LC::Exception::Context->new->will_store_all;
our @ISA = qw(NCM::Component);
use EDG::WP4::CCM::Path 16.8.0 qw(unescape);

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
use constant RPM_QUERY_INSTALLED_NAMES => qw(rpm -qa --nosignature --nodigest --qf %{EPOCH}:%{NAME}\n);
use constant RPM_QUERY_INSTALLED_NAMES_NOEPOCH => qw(rpm -qa --nosignature --nodigest --qf %{NAME}\n);
use constant REPO_AVAIL_PKGS     => qw(repoquery -C --show-duplicates --all --qf %{EPOCH}:%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH});
use constant YUM_PLUGIN_OPTS     => "--disableplugin=\* --enableplugin=fastestmirror --enableplugin=versionlock --enableplugin=priorities";
use constant YUM_TEST_CHROOT     => qw(/tmp/spma_yum_testroot);
use constant SPMA                => "/software/components/spma";
use constant SPMAPROXY           => "/software/components/spma/proxy";

our $NoActionSupported = 1;

=pod

=head2 C<execute_command>

Executes C<$command> for reason C<$why>. Optionally with standard
input C<$stdin>.  The command may be executed even under --noaction if
C<$keeps_state> has a true value.

If the command is executed, this method returns its standard output
upon success or C<undef> in case of error.  If the command is not
executed the method always returns a true value (usually 1, but don't
rely on this!).

The return value is ordered set of (exit code, stdout, stderr) as a
result of the executed command.

=cut

sub execute_command
{
    my ( $self, $command, $why, $keeps_state, $stdin, $nolog ) = @_;

    my ( %opts, $out, $err, @missing );

    %opts = ( log => $self,
        stdout      => \$out,
        stderr      => \$err,
        keeps_state => $keeps_state );

    $opts{stdin} = $stdin if defined($stdin);

    my $cmd = CAF::Process->new( $command, %opts );

    $cmd->info("$why");
    $self->log("[EXEC] ", join(" ", @$command));
    $cmd->execute();
    if ( !defined($nolog) ) {
        $self->log("$why stderr:\n$err") if ( defined($err) && $err ne '' );
        $self->log("$why stdout:\n$out") if ( defined($out) && $out ne '' );
    }

    if ( $NoAction && !$keeps_state ) {
        return ( 0, undef, undef );
    }

    return ( $?, $out, $err );
}

=pod

=head2 C<execute_yum_command_with_recovery>

Executes C<$execute_yum_command> and tries to fix possible problems
on  best-effort basis. That means it attempts to fix broken transaction
via offending package(s) removal and then re-executing the transaction.

=cut

sub execute_yum_with_recovery
{
    my ( $self, $command, $why, $keeps_state, $stdin ) = @_;
    my ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command($command, $why, $keeps_state, $stdin);

    return ( $cmd_exit, $cmd_out, $cmd_err ) if $NoAction;

    my @lines = split /\n/, $cmd_out . $cmd_err;
    my $packages_to_remove = Set::Scalar->new();
    foreach my $line (@lines) {
        my $cf = index($line, 'conflicts with file from package');
        if ( $cf != -1) {        # handle file conflicts
            my $pkg = $line;
            $pkg =~ s,^.*package ,,;
            $pkg =~ s,-[0-9]*:,-,;
            $self->warn("$pkg will be removed to avoid file conflict");
            $packages_to_remove->insert($pkg) if !$packages_to_remove->has($pkg);
        } else {
            $cf = index($line, 'Error: ');
            my $pkg = $line;
            if ( $cf != -1 && index($line, 'conflicts with') != -1 ) {        # handle package conflicts
                $pkg =~ s,^.*Error: ,,;
                $pkg =~ s,^.*Package: ,,;
                $pkg =~ s, .*,,;
                $self->warn("$pkg will be removed to avoid package conflict");
                $packages_to_remove->insert($pkg) if !$packages_to_remove->has($pkg);
            } else {
                my $dep = index($line, 'is needed by (installed)');
                if ( $dep != -1) {
                    my $pkg = $line;
                    $pkg =~ s,^.*\(installed\) ,,;
                    $pkg =~ s,-[0-9]*:,-,;
                    $self->warn("$pkg will be removed to avoid file conflict");
                    $packages_to_remove->insert($pkg) if !$packages_to_remove->has($pkg);
                }
            }
        }
    }

    if ( $packages_to_remove->size ) {
        ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command([ "yum remove -y " . YUM_PLUGIN_OPTS . " " . join (" ", sort @$packages_to_remove) ], 'attempting to remove: '.join (" ", sort @$packages_to_remove), $keeps_state, $stdin);

        if ( index($cmd_out . $cmd_err, 'Error: ') != -1 ) {
            $self->error("Unable to remove conflicting packages.");
        } else {
            ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command($command, 'retrying: '.$why, $keeps_state, $stdin);
        }
    }

    return ( $cmd_exit, $cmd_out, $cmd_err );
}

sub get_installed_rpms
{
    my ( $self ) = @_;
    my ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( [RPM_QUERY_INSTALLED], "getting list of installed packages", 1, "/dev/null", 1 );
    if ( $cmd_exit ) {
        $self->error("Error getting list of installed packages.");
        return undef;
    }
    my $preinstalled_rpms = $cmd_out;
    $preinstalled_rpms =~ s/\(none\)/0/g;
    return Set::Scalar->new( split ( /\n/, $preinstalled_rpms ) );
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

    # Detect OS
    my $fhi;
    my $os_major;
    if ( open( $fhi, '<', "/etc/redhat-release" ) ) {
        while ( my $line = <$fhi> ) {
            my $i = index($line, 'release ');
            if ( $i >= 0 ) {
                chomp($line);
                $self->info("local OS: ".$line);
                $os_major = substr($line, $i+8, 1);
                last;
            }
        }
        $fhi->close();
    }

    if ( $os_major eq "" ) {
        $self->error("Unable to determine OS release.");
        return 0;
    }

    my ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( ["rpm -q --qf %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH} ncm-spma"], "checking for spma version", 1);
    if ( $cmd_exit ) {
        $self->warn("Error getting SPMA version.");
    } else {
        $self->info("SPMA version: ", $cmd_out);
    }
    $self->info("user packages permitted: $t->{userpkgs}");

    # Convert these crappily-defined fields into real Perl booleans.
    $t->{run}      = $t->{run} eq 'yes';
    $t->{userpkgs} = defined( $t->{userpkgs} ) && $t->{userpkgs} eq 'yes';

    # Test if we are supposed to be running spma in package modification mode.
    if ( -e "/.spma-run" ) {
        if ( !unlink "/.spma-run" ) {
            $self->error("Unable to remove file /.spma-run: $!");
        }
        $t->{run} = 1;
    }

    # Generate YUM config file
    my $yum_conf_file = CAF::FileWriter->new( YUM_CONF_FILE, log => $self );
    my $excludes      = $t->{excludes};
    print $yum_conf_file $t->{yumconf};
    print $yum_conf_file "exclude=" . join ( " ", sort @$excludes );
    $yum_conf_file->close();

    if (!$NoAction) {
        my @repos = glob "/etc/yum.repos.d/*.repo";
        foreach my $repo (@repos) {
            if ( !unlink $repo ) {
                $self->error("Unable to remove file $repo: $!");
                return 0;
            }
        }
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
        my $repofile = "[$repo->{name}]\nname=$repo->{name}\nbaseurl=$urls\nenabled=$repo->{enabled}\n";
        if ( defined( $repo->{mirrorlist} ) && $repo->{mirrorlist} ) {
            $repofile = "[$repo->{name}]\nname=$repo->{name}\nmirrorlist=$url\nenabled=$repo->{enabled}\n";
        }
        $repofile .= "priority=$repo->{priority}\n" if ( defined($repo->{priority}) );
        $repofile .= "gpgcheck=$repo->{gpgcheck}\n" if ( defined($repo->{gpgcheck}) );
        print $fh "# File generated by " . __PACKAGE__ . ". Do not edit\n";
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
        if ( !$found_spma && substr( (unescape $name), 0, 8 ) eq 'ncm-spma' ) {
            $found_spma = 1;
        }
        my $vra = $pkgs->{$name};
        while ( my ( $vers, $a ) = each(%$vra) ) {
            my $arches = $a->{arch};
            if ( exists( $a->{repository} ) ) {
                foreach my $arch (@$arches) {
                    if ( $vers ne '_' ) {
                        push ( @pkl_v, (unescape $name) . ';' . (unescape $vers) . '.' . $arch );
                    } else {
                        if ( $arch eq '_' ) {
                            push ( @pkl, (unescape $name) . ';' );
                        } else {
                            push ( @pkl_a, (unescape $name) . ';' . $arch );
                        }
                    }
                }
            } else {
                foreach my $arch ( keys %$arches ) {
                    if ( $vers ne '_' ) {
                        push ( @pkl_v, (unescape $name) . ';' . (unescape $vers) . '.' . $arch );
                    } else {
                        if ( $arch eq '_' ) {
                            push ( @pkl, (unescape $name) . ';' );
                        } else {
                            push ( @pkl_a, (unescape $name) . ';' . $arch );
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

    my $wanted_pkgs_uv = Set::Scalar->new(@pkl);          # packages without version/arch specified
    my $wanted_pkgs_v  = Set::Scalar->new(@pkl_v);        # packages with only version specified
    my $wanted_pkgs_a  = Set::Scalar->new(@pkl_a);        # packages with only arch specified
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

    # Remove old (also possibly duplicated) GPG keys
    ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( ["rpm -e --allmatches gpg-pubkey"], "removing old GPG keys" );
    if ( $cmd_exit ) {
        $self->warn("Failed to remove old GPG keys from rpmdb. None installed?");
    }
    # Import GPG keys
    foreach my $file ( glob "/etc/pki/rpm-gpg/*" ) {
        ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( ["rpm -v --import $file"], "importing GPG key $file" );
        if ( $cmd_exit ) {
            $self->error("Failed to import $file GPG key to rpmdb.");
            return 0;
        }
    }

    # RHEL7 needs converting groups
    if ( $os_major eq '7' ) {
        ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( [ "yum groups mark convert " . YUM_PLUGIN_OPTS ], "converting groups", 1 );
        if ( $cmd_exit ) {
            $self->error("Failed to do group conversion on RHEL7.");
            return 0;
        }
    }

    # Get list of packages installed on system before any package modifications.
    my $preinstalled = $self->get_installed_rpms();
    return 1 if !defined($preinstalled);

    # Clean up YUM state - worth to be thorough there
    # Expiration of cache is not enough sometimes.
    # https://bugzilla.redhat.com/show_bug.cgi?id=1151074
    if ( $t->{run} ) {
        $self->execute_command( ["yum clean all " . YUM_PLUGIN_OPTS], "resetting YUM state", 0 );
        $self->execute_command( ["yum makecache " . YUM_PLUGIN_OPTS], "generating YUM cache", 0 );
    }

    my @files = glob "{/tmp/*.yumtx,/var/lib/yum/transaction*}";
    foreach my $file (@files) {
        if ( !unlink $file ) {
            $self->warn("unable to remove file $file: $!");
        }
    }
    my @dirs = glob "/var/tmp/yum-root*";
    foreach my $dir (@dirs) {
        if ( !rmtree $dir) {
            $self->warn("unable to remove directory $dir: $!");
        }
    }

    # Test whether comps/groups are sane.
    ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( [ "yum groupinfo core " . YUM_PLUGIN_OPTS ], "testing comps/groups sanity", 1 );
    if ( $cmd_exit ) {
        $self->error("Groups are not sane - core group missing. Will not continue.");
        return 0;
    }

    # Query metadata for version locked packages including Epoch and write versionlock.list
    ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( [REPO_AVAIL_PKGS], "fetching full package list", 1, "/dev/null", 1 );
    if ( $cmd_exit ) {
        $self->error("Error fetching full package list.");
        return 0;
    }
    my $repodata_rpms = $cmd_out;

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
            $self->error( "Version-locked packages are missing from repositories - expected ", $wanted_pkgs_locked->size, ", available ", $locked_found->size, "\n",
                          "Missing packages: ", $wanted_pkgs_locked - $locked_found_noepoch );
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
    return 1 unless $t->{run};

    # Run test transaction to get complete list of packages to be present on the system
    my $groups           = $config->getElement(GROUPS_TREE)->getTree();
    $self->execute_command( [ "rm -rf " . YUM_TEST_CHROOT ], "cleaning YUM test chroot", 1 );
    $self->execute_command( [ "mkdir -p " . YUM_TEST_CHROOT . "/var/cache" ],                 "setting up YUM test chroot",    1 );
    $self->execute_command( [ "ln -s /var/cache/yum " . YUM_TEST_CHROOT . "/var/cache/yum" ], "setting YUM test chroot cache", 1 );
    my $yum_install_test_command = "yum install " . YUM_PLUGIN_OPTS . " -C --installroot=" . YUM_TEST_CHROOT;
    if (@$groups)             { $yum_install_test_command .= " @" . join   ( " @",   sort @$groups ); }
    if (@$wanted_pkgs_locked) { $yum_install_test_command .= " " . join    ( " ",    sort @$wanted_pkgs_locked ); }
    if (@$wanted_pkgs)        { $yum_install_test_command .= " " . join    ( " ",    sort @$wanted_pkgs ); }
    ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( [$yum_install_test_command], "performing YUM chroot install test", 1, "/dev/null", "verbose", 1 );
    $self->error($cmd_err) if $cmd_err;
    my $yum_install_test = $cmd_out;
    $yum_install_test = $cmd_err if ($os_major eq '7');
    $self->execute_command( [ "rm -rf " . YUM_TEST_CHROOT ], "removing YUM test chroot", 1 );

    # Parse YUM output to get full package list
    my $to_install = Set::Scalar->new;
    my $to_install_names = Set::Scalar->new;
    if ( $os_major > '5' ) {
        # RHEL6+ falls here - we don't support anything older than RHEL5
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
            $to_install_names->insert($name) if !$to_install_names->has($name);
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
            $to_install_names->insert($name) if !$to_install_names->has($name);
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

    my $installed = $preinstalled;
    my $whitelist = $t->{whitelist};

    if ( !$t->{userpkgs} ) {
        # Attempt to remove packages not wanted by the result of test transaction.
        ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( [RPM_QUERY_INSTALLED_NAMES_NOEPOCH], "getting list of installed package names without epoch", 1, "/dev/null", 1 );
        if ( $cmd_exit ) {
            $self->error("Error getting list of installed package names.");
            return 0;
        }
        my $installed_names = Set::Scalar->new( split ( /\n/, $cmd_out ) );
        my $packages_to_remove = $installed_names - $to_install_names;
        $packages_to_remove->delete('gpg-pubkey');
        if ( defined($whitelist) ) {
            for my $rpm ( $packages_to_remove->elements ) {
                for my $white_pkg (@$whitelist) {
                    if ( index($rpm, $white_pkg) == 0 || match_glob($white_pkg, $rpm) ) {
                        $packages_to_remove->delete($rpm);
                    }
                }
            }
        }
        if ( !$packages_to_remove->is_empty ) {
            ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command([ "yum remove -y " . YUM_PLUGIN_OPTS . " " . join (" ", sort @$packages_to_remove) ], 'attempting to remove: '.join (" ", sort @$packages_to_remove));
            $installed = $self->get_installed_rpms();
            return 1 if !defined($installed);
            my $removed = $preinstalled - $installed;
            if ( !$removed->is_empty ) {
                $self->info("removed " . $removed->size . " unneeded package(s): " . $removed );
            }
        }
    }

    my $to_sync = $to_install - $installed;
    if ( !$to_sync->is_empty ) {
        # Attempt to only downgrade packages which are installed.
        ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command( [RPM_QUERY_INSTALLED_NAMES], "getting list of installed package names", 1, "/dev/null", 1 );
        if ( $cmd_exit ) {
            $self->error("Error getting list of installed package names.");
            return 0;
        }
        my $installed_rpm_names = $cmd_out;
        $installed_rpm_names =~ s/\(none\)/0/g;
        my $installed_names = Set::Scalar->new( split ( /\n/, $installed_rpm_names ) );
        for my $rpm (@$to_sync) {
            my $found = 0;
            for my $rpmname (@$installed_names) {
                if ( index($rpm, $rpmname) == 0 ) {
                        $found = 1;
                        last;
                }
            }
            if ( $found == 0 ) {
                $to_sync->delete($rpm);
            }
        }
    }
    if ( !$to_sync->is_empty ) {
        # YUM distro-sync can be buggy - in that case use downgrade approach for version locked packages
        # installation will be executed later on
        my $pre = $installed;
        ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_yum_with_recovery( [ "yum downgrade -q -y " . YUM_PLUGIN_OPTS . " " . join ( " ", sort @$to_sync ) ], "downgrading packages" );
        if ( $cmd_exit ) {
            $self->error("Error downgrading packages:\n$cmd_err");
            return 0;
        }
        $installed = $self->get_installed_rpms();
        return 1 if !defined($installed);
        my $downgraded_to = $installed - $pre;
        if ( !$downgraded_to->is_empty ) {
            $self->info("downgraded ".$downgraded_to->size." package(s) to: ", $downgraded_to);
        }
        $pre = $installed;
        ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_yum_with_recovery( [ "yum update -q -y " . YUM_PLUGIN_OPTS ], "updating packages" );
        if ( $cmd_exit ) {
            $self->error("Error updating packages:\n$cmd_err");
            return 0;
        }
        $installed = $self->get_installed_rpms();
        return 1 if !defined($installed);
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
        ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_yum_with_recovery( [ "yum install -y " . YUM_PLUGIN_OPTS . " " . join( " ", sort @$will_install) ], "installing ".$will_install->size." package(s)" );
        if ( index($cmd_out, 'Complete!') == -1 ) {
            $self->error("Error installing packages:\n$cmd_err");
            return 0;
        }
        $installed = $self->get_installed_rpms();
        return 1 if !defined($installed);
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
        if ( !$t->{userpkgs} ) {
            while ( defined( my $p = $will_remove->each ) ) {
                if ( substr( $p, 0, 8 ) eq 'ncm-spma' ) {
                    $self->error("Attempting to remove ncm-spma! You seem to miss SELF from /software/packages = {}?");
                    return 0;
                }
            }
            my $pre = $installed;
            ( $cmd_exit, $cmd_out, $cmd_err ) = $self->execute_command([ "yum remove -y " . YUM_PLUGIN_OPTS . " " . join (" ", sort @$will_remove) ], 'attempting to remove: '.join (" ", sort @$will_remove));
            $installed = $self->get_installed_rpms();
            return 1 if !defined($installed);
            my $removed = $pre - $installed;
            if ( !$removed->is_empty ) {
                $self->info("removed " . $removed->size . " package(s): ", $removed);
            }
        } else {
            $self->info( "userpkgs enabled, will not remove " . $will_remove->size . " user packages: ", join ( " ", sort @$will_remove ) );
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
    if (open(my $fh, "<", "/var/cache/yum/timedhosts.txt")) {
        local($/); $self->info("latency of proxies:\n" . <$fh>); close($fh);
    } else {
        $self->error("cannot open proxy stats file");
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
