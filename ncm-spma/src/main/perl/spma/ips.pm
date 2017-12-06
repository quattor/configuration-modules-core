# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

package NCM::Component::spma::ips;

use strict;
use warnings;
use NCM::Component;
our $EC=LC::Exception::Context->new->will_store_all;
our @ISA = qw(NCM::Component);
use EDG::WP4::CCM::Path 16.8.0 qw(unescape);

use CAF::Process;
use CAF::FileWriter;
use LC::Exception qw(SUCCESS);
use File::Path;
use Set::Scalar;
use IPS;

umask(022);

#
# May need to reinstate this if we wish for this component
# to drive IPS publisher config
#
#use constant REPOS_TREE => "/software/repositories";

use constant CMP_TREE => "/software/components/spma";
use constant BEADM_LIST => [qw(/usr/sbin/beadm list -H)];
use constant PKG_LIST => [qw(/usr/bin/pkg list -H)];
use constant PKG_LIST_V => [qw(/usr/bin/pkg list -Hv)];
use constant PKG_IMAGE_CREATE => [qw(/usr/bin/pkg image-create -Ff)];
use constant PKG_PUBLISHER => [qw(/usr/bin/pkg publisher -HF tsv)];
use constant PKG_SET_PUBLISHER => [qw(/usr/bin/pkg -R <rootdir> set-publisher)];
use constant PKG_AVOID => [qw(/usr/bin/pkg avoid)];
use constant SPMA_RUN_NOACTION => [qw(/usr/bin/spma-run --noaction)];
use constant SPMA_RUN_EXECUTE => [qw(/usr/bin/spma-run --execute)];
use constant PKG_INSTALL_NV => [qw(/usr/bin/pkg -R <rootdir> install -nv)];
use constant PKG_HELP => [qw(/usr/bin/pkg --help)];
use constant SPMA_IMAGEDIR => "/var/tmp/.ncm-spma-image";

use constant PKG_NO_CHANGES => 4;      # if pkg returns 4 or spma-run returns 1
use constant SPMA_RUN_NO_CHANGES => 1; # then there was nothing to do

#
# Returns a hash with packages in the given nlist.
# Can be given an existing hash to amend.
#
sub gethash_ips
{
    my ($self, $pkgs, $hash) = @_;

    $hash ||= {};

    while (my ($pkg, $st) = each(%$pkgs)) {
        my $done = 0;
        if (exists $st->{version}) {
            $hash->{unescape($pkg)} = unescape($st->{version});
            $done = 1;
        }
        while (my ($ver) = each(%$st)) {
            next if $ver eq 'version';
            $hash->{unescape($pkg)} = unescape($ver);
            $done = 1;
        }
        $hash->{unescape($pkg)} = "" if ! $done;
    }

    return $hash;
}

#
# Return a new set of installed packages.
#
sub load_installed_set
{
    my ($self) = @_;
    my $set = Set::Scalar->new();

    my $proc = CAF::Process->new(PKG_LIST, log => $self, keeps_state => 1);
    my @output = split /\n/, $proc->output();
    die "cannot get list of packages" if $?;
    for my $line (@output) {
        $line =~ s/ .*$//;
        $set->insert($line);
    }
    return $set;
}

#
# Adds IDRs to given hash.
#
sub reject_idrs
{
    my ($self, $reject, $installed_set) = @_;

    my @pkgs = @$installed_set;
    for my $line (grep /^idr[0-9]/, @pkgs) {
        $reject->{(split / /, $line)[0]} = "";
    }
    return $reject;
}

#
# Returns a hash of frozen IPS packages.
#
sub frozen_ips
{
    my ($self) = @_;

    my %hash;
    my $proc = CAF::Process->new(PKG_LIST_V, log => $self, keeps_state => 1);
    my $out = $proc->output();

    my @output;
    @output = split /\n/, $out if defined($out);

    die "cannot get verbose list of packages" if $?;
    for (grep / if.$/, @output) {
        my ($pkg, $ver) = split /@/, (split / /)[0];
        $hash{$pkg} = $ver;
    }
    return \%hash;
}

#
# Take array of package names / versions, i.e. output of pkg_keys(),
# by reference and return a hash containing just those packages that are
# currently installed on the system at the given version number
#
sub get_exact_pkgs
{
    my ($self, $pkglist) = @_;

    my %hash;
    my $cmd = PKG_LIST_V;
    push @$cmd, @$pkglist;
    my $proc = CAF::Process->new(PKG_LIST_V, log => $self, keeps_state => 1);
    my $out = $proc->output();

    my @output;
    @output = split /\n/, $out if defined($out);

    for (grep / i..$/, @output) {
        s,^(pkg://[^/]*/|pkg:/|/),,;
        my ($pkg, $ver) = split /@/, (split / /)[0];
        $hash{$pkg} = $ver;
    }
    return \%hash;
}

#
# Creates an image suitable for dry-run package operations.
#
sub image_create
{
    my ($self, $dir) = @_;

    if (-d $dir and (! -o $dir or ! -d "$dir/var/pkg")) {
        rmtree($dir) or die "wrong owner, cannot remove $dir: $!";
    }

    #
    # Prepare to create a new image directory, but will only actually
    # populate it and use it if we don't already have one of if the
    # list of publishers has changed since the last time it was created
    #
    my $newdir = "$dir.new";
    if (-d $newdir) {
        rmtree($newdir) or die "wrong owner, cannot remove $newdir: $!";
    }
    mkdir($newdir) or die "cannot create directory $newdir: $!";

    #
    # Copy publisher configuration from existing system to
    # new image directory
    #
    # N.B. this is incomplete as it only copies the publisher URI
    # and does not currently take account of other publisher properties
    #
    my $proc = CAF::Process->new(PKG_PUBLISHER, log => $self, keeps_state => 1);
    my $out = $proc->output();
    die "cannot get publishers" if $?;

    my @output;
    @output = split /\n/, $out if defined($out);

    my $pubcfg = "$dir/pkg-publisher.conf";
    my $pubcfg_new = "$newdir/pkg-publisher.conf";
    my $fh;
    open($fh, ">", $pubcfg_new) or die "cannot write to $pubcfg_new: $!";
    my @pubcmds;
    for (@output) {
        my ($publisher, $sticky, $syspub, $enabled, $type,
            $status, $uri, $proxy) = split;

        next unless $enabled eq 'true' and $type eq 'origin' and defined($uri);

        my $cmd = PKG_SET_PUBLISHER;
        my @cmd = @$cmd;
        push @cmd, "-g", $uri, $publisher;
        $cmd[2] = $dir;
        print $fh join(" ", @cmd) . "\n";
        $cmd[2] = $newdir;
        push @pubcmds, [@cmd];
    }
    close($fh) or die "cannot close $pubcfg_new: $!";

    if (-d $dir) {
        #
        # Delete existing image directory if publisher configuration
        # has changed since it was created
        #
        my $result = LC::Check::file(undef,
                                     source      => $pubcfg_new,
                                     destination => $pubcfg,
                                     owner       => $<,
                                     mode        => 0644);
        if ($result) {
            unless (rmtree($dir)) {
                unlink($pubcfg);
                die "cannot remove $dir: $!";
            }
        }
    }

    unless (-d $dir) {
        #
        # Run pkg image-create to create an image directory
        # that can be used for package operations
        #
        my $cmd = PKG_IMAGE_CREATE;
        my $proc = CAF::Process->new($cmd, log => $self, keeps_state => 1);
        $proc->pushargs($newdir);
        $proc->run();
        die "failed to create image" if $?;

        #
        # Run pkg set-publisher commands written to configuration
        # file earlier
        #
        for $cmd (@pubcmds) {
            $proc = CAF::Process->new($cmd, log => $self, keeps_state => 1);
            $proc->run();
            die "failed to set publisher in image directory: '" .
                join(" ", @$cmd) . "' failed" if $?;
        }

        rename($newdir, $dir) or die "cannot rename $newdir to $dir: $!";
    } else {
        rmtree($newdir);
    }
}

#
# Get set of packages that would be installed in a fresh image.
#
sub get_fresh_pkgs
{
    my ($self, $wanted, $imagedir) = @_;

    #
    # Create new empty image directory, simulating fresh install
    #
    $self->image_create($imagedir);

    #
    # Run pkg install command that would be run against the empty
    # image directory (minus any BE options), but in dry-run verbose
    # mode and capture the output which tells us exactly which list of
    # packages IPS would have installed
    #
    my $pkgcmd = PKG_INSTALL_NV;
    $$pkgcmd[2] = $imagedir;

    for (@$wanted) { push @$pkgcmd, $_; }

    $self->info("performing dry-run package install in empty image");
    my @output = split /\n/, $self->run_pkg_command($pkgcmd, 0,
                                                    PKG_NO_CHANGES);
    my $start = 0;
    my $fresh_set = Set::Scalar->new();
    for my $line (@output) {
        $start = 1 if $line =~ /Changed packages:/;
        last if $line =~ /Services:/;
        next unless $start;
        next unless $line =~ /^  \w/;
        $line =~ s/^  //;
        $fresh_set->insert($line);
    }

    return $fresh_set;
}

#
# Returns the list of IPS packages to remove. A package must be removed if
# it is a leaf package and is not listed in $wanted.
#
sub ips_to_remove
{
    my ($self, $fresh_set, $installed_set) = @_;

    #
    # Compare list of fresh packages with list of currently
    # installed packages, any differences are user packages
    # to reject
    #
    my $reject_set = $installed_set - $fresh_set;
    my @rm_list = @$reject_set;

    #
    # Exclude IDRs because they are processed separately
    #
    @rm_list = grep !/^idr[0-9]/, @rm_list;

    $self->info(scalar(@rm_list) . " user package(s) to reject");
    $self->log("user packages to reject: " .
               join(" ", @rm_list)) if @rm_list;
    return \@rm_list;
}

#
# Gets a unique BE name on Solaris
#
sub get_unique_be
{
    my ($self, $beadm_list, $bename) = @_;

    my $benum = 0;
    for my $line (split /^/, $beadm_list) {
        chomp $line;
        $line =~ s/;.*$//;
        if ($line eq $bename and ! $benum) {
            $benum = 1;
        } elsif ($line =~ /^$bename-\d$/) {
            $line =~ s/^.*-//;
            $benum = $line + 1;
        }
    }

    #
    # If any BEs exist that match the elected BE name
    # or the format bename-<number> then the highest
    # unused number will be appended
    #
    $bename .= "-$benum" if $benum;
    return $bename;
}

#
# Merges package lists from multiple resource paths.
#
sub merge_pkg_paths
{
    my ($self, $config, $respath) = @_;
    my %merged_pkgs;

    for my $path (@$respath) {
        next unless $config->elementExists($path);
        my $pkgs = $config->getElement($path)->getTree();
        if (!%merged_pkgs) {
            %merged_pkgs = %{$pkgs};
        } else {
            while (my ($pkg, $st) = each(%$pkgs)) {
                if (exists $merged_pkgs{$pkg}) {
                    while (my ($ver, $archs) = each(%$st)) {
                        $merged_pkgs{$pkg}{$ver} = $archs;
                    }
                }
                else {
                    $merged_pkgs{$pkg} = $st;
                }
            }
        }
    }
    return \%merged_pkgs;
}

#
# Runs pkg or spma-run command and interprets exit status.
# Note that this is only suitable for commands that do not change state.
#
sub run_pkg_command
{
    #
    # If $log is 1, command output is sent to the CAF log and this subroutine
    # returns the command exit status.  If $log is 0, command output is not
    # logged and instead this subroutine returns the output.
    #
    # $exit_void provides the exit status code that the command will return
    # with if there is nothing to do.
    #   (4 for /usr/bin/pkg, 1 for /usr/bin/spma-run)
    #
    my ($self, $cmd, $log, $exit_void) = @_;
    my $proc = CAF::Process->new($cmd, log => $self, keeps_state => 1);
    my $output = $proc->output();
    $output = "" unless defined($output);

    my $status = $?;
    my $sdesc;
    my $do_err = 0;
    my $exitcode = $status >> 8;
    if ($exitcode or ! $status) {
        $sdesc = "returned exit status " . $exitcode;
        if ($exitcode == $exit_void) {
            #
            # This exit status indicates that no changes would be made
            #
            $sdesc .= " (nothing to do)";
        } elsif ($exitcode) {
            #
            # This exit status indicates that an error occurred
            #
            $do_err = 1;
        }
    } else {
        $sdesc = "interrupted by signal: " . ($status & 255);
        $do_err = 1;
    }

    if ($do_err) {
        $self->error($output);
        die "$$cmd[0] $sdesc";
    }

    $self->verbose($output);

    if ($log) {
        $self->log($output);
    }
    $self->log("$$cmd[0] $sdesc") if ! $do_err;

    #
    # Returns command output if it wasn't written to the log file
    #
    return $output unless $log;

    #
    # Returns exit status if command output was written to the log
    #
    return $exitcode;
}

#
# Get pkg@ver keys from hash where ver is actually the value.
# Can be given an existing array, by reference, to amend.
#
sub pkg_keys
{
    my ($self, $hash, $keylist) = @_;

    $keylist ||= [];

    for my $pkg (keys %$hash) {
        my $ver = "";
        $ver = "\@$hash->{$pkg}" if $hash->{$pkg} ne "";
        push @$keylist, "$pkg$ver";
    }
    return $keylist;
}

#
# Returns >0 if pkg command on this system has exact-install capability
# introduced in Solaris 11.2
#
sub pkg_has_exact_install
{
    my $self = shift;
    my $stderr;
    my $proc = CAF::Process->new(PKG_HELP, stderr => \$stderr,
                                 keeps_state => 1);
    $proc->execute();
    my $result = scalar(grep /exact-install/, split('\n', $stderr));
    if ($result == 0) {
        $self->info("This system does not have pkg exact-install");
    } else {
        $self->info("This system has pkg exact-install");
    }
    return $result;
}

#
# Updates IPS packages on the system.
#
sub update_ips
{
    my ($self, $pkgs, $reject, $uninst, $whitelist,
            $run_now, $allow_user_pkgs, $cmdfile, $flagfile,
            $bename, $rejectidr, $freeze, $imagedir) = @_;

    #
    # Delete flagfile now, so the result cannot be misinterpreted
    # if this component exits prematurely
    #
    unlink($flagfile) if $flagfile and ! $NoAction;

    #
    # Check that BE active now and BE active after reboot
    # are the same, otherwise we cannot operate reliably
    #
    my $proc = CAF::Process->new(BEADM_LIST, log => $self);
    my $beadm_list = $proc->output();
    die "cannot get list of BEs" if $?;
    unless (defined($beadm_list) and grep /;NR;/, $beadm_list) {
        $self->error("current BE is not active after reboot, terminating");
        return 0;
    }

    my $exact_install;
    if ($allow_user_pkgs) {
        #
        # If we are allowing user packages, we will not use pkg exact-install
        #
        $exact_install = 0;
        $self->info("Allowing user packages, will not use pkg exact-install");
    } elsif (scalar(%$uninst)) {
        #
        # If there are packages on the uninstall list, then we cannot
        # use pkg exact-install even if it is available, because it will
        # do the wrong thing and remove orphan dependencies as well
        #
        $exact_install = 0;
        $self->info("Packages found on uninstall list, will not use " .
                    "pkg exact-install which would also remove orphan " .
                    "dependencies");
    } else {
        #
        # Determine whether this version of Solaris is new enough to support
        # the pkg exact-install command, which speeds this process up
        #
        $exact_install = $self->pkg_has_exact_install();
    }

    #
    # Get list of packages to process
    #
    my $wanted = $self->gethash_ips($pkgs);
    my $wanted_keys = $self->pkg_keys($wanted);
    $self->info(scalar(@$wanted_keys) . " package(s) requested");
    $self->log("requested packages: " . join(" ", @$wanted_keys))
        if @$wanted_keys;

    my $installed_set = $self->load_installed_set()
        if $rejectidr or !$allow_user_pkgs;

    $reject = $self->gethash_ips($reject);
    $self->gethash_ips($uninst, $reject);
    my $reject_keys;
    if (!$rejectidr or $exact_install) {
        #
        # If rejectidr is false, or if we are using pkg exact-install,
        # we do not add IDR packages to the reject list
        #
        $reject_keys = $self->pkg_keys($reject);

        unless ($rejectidr) {
            #
            # If rejectidr is false, add all installed IDRs to the whitelist
            # so that they will appear in the list of packages to install
            #
            my %idrhash;
            $self->reject_idrs(\%idrhash, $installed_set);

            my %wanted_merge = (%$wanted, %idrhash);
            $wanted = \%wanted_merge;

            #
            # Recompute keys
            #
            $wanted_keys = undef;
        }
    } else {
        #
        # If rejectidr is true and we are not using pkg exact-install,
        # add all IDR packages to the reject list
        #
        $self->reject_idrs($reject, $installed_set);
        $reject_keys = $self->pkg_keys($reject);
    }
    $self->info(scalar(@$reject_keys) . " package(s) rejected");
    $self->log("rejected packages: " . join(" ", @$reject_keys))
        if @$reject_keys;

    $whitelist = $self->gethash_ips($whitelist);
    my $whitelist_keys = $self->pkg_keys($whitelist);
    $self->info(scalar(@$whitelist_keys) . " package(s) whitelisted");
    $self->log("whitelisted packages: " . join(" ", @$whitelist_keys))
        if @$whitelist_keys;

    my $frozen;
    if ($freeze and %{$frozen = $self->frozen_ips()}) {
        #
        # We are ignoring frozen packages, this is achieved by adding
        # frozen packages at their exact current version number to
        # the list of wanted packages
        #
        my $frozen_keys = $self->pkg_keys($frozen);
        $self->info(scalar(@$frozen_keys) . " package(s) frozen");
        $self->log("frozen packages: " . join(" ", @$frozen_keys))
            if @$frozen_keys;

        my %wanted_merge = (%$wanted, %$frozen);
        $wanted = \%wanted_merge;

        #
        # Recompute keys
        #
        $wanted_keys = undef;
    }

    my $whitepkgs;
    if (@$whitelist_keys and %{$whitepkgs =
                                $self->get_exact_pkgs($whitelist_keys)}) {
        #
        # Packages installed on the system that appear on the whitelist must
        # be added to the wanted list at their exact current version number
        #
        my %wanted_merge = (%$wanted, %$whitepkgs);
        $wanted = \%wanted_merge;

        #
        # Recompute keys
        #
        $wanted_keys = undef;
    }

    #
    # Recompute keys if needed
    #
    $wanted_keys = $self->pkg_keys($wanted) unless defined($wanted_keys);

    my $to_rm;
    unless ($exact_install) {
        my $fresh_set;
        unless ($allow_user_pkgs) {
            $self->info("finding user packages");

            #
            # Get set of packages that would be installed in a fresh image
            #
            $fresh_set = $self->get_fresh_pkgs($wanted_keys, $imagedir);

            #
            # Convert into an array of user packages to remove
            #
            $to_rm = $self->ips_to_remove($fresh_set, $installed_set);
        }

        #
        # If there is an avoid list, and there are packages on the avoid
        # list that are not on the uninstall or reject lists, then we need to
        # consider whether to explicitly install them or not
        #
        $proc = CAF::Process->new(PKG_AVOID, log => $self);
        my $out = $proc->output();

        my @output;
        @output = split /\n/, $out if defined($out);

        if (@output) {
            my (%pkg_map, %avoid);
            for (@output) {
                s/^\s+//;
                my $pkg = (split / /)[0];
                IPS::Package::pkg_add_lookup($pkg, 1, \%pkg_map);
                $avoid{$pkg} = 1;
            }
            for (keys %$reject) {
                s,^(pkg://[^/]*/|pkg:/|/),,;
                for my $pkg (IPS::Package::pkg_lookup_installed($_,
                                                                \%pkg_map)) {
                    delete $avoid{$pkg};
                }
            }
            if (%avoid) {
                $self->info("processing avoid list");
                $self->verbose("avoided package(s) to verify: " .
                           join(" ", keys %avoid));
                unless (defined $fresh_set) {
                    #
                    # Get set of packages that would be installed in a
                    # fresh image (but only if we haven't already got
                    # this information)
                    #
                    $fresh_set = $self->get_fresh_pkgs($wanted_keys, $imagedir);
                }
                my @rm_avoid;
                for my $pkg (keys %avoid) {
                    push @rm_avoid, $pkg if $fresh_set->has($pkg) and
                                            !$wanted->{$pkg};
                }
                if (@rm_avoid) {
                    $self->info(scalar(@rm_avoid) .
                                " package(s) no longer avoiding");
                    $self->log("package(s) to remove from avoid list " .
                               "by explicit install: " . join(" ", @rm_avoid));
                    push @$wanted_keys, @rm_avoid;
                }
            }
        }
    }

    #
    # Write command file
    #
    my $fh = CAF::FileWriter->new($cmdfile, log => $self,
                                  owner => $<, mode => 0644);

    my $install_cmd;
    if ($exact_install) {
        $install_cmd = "exact-install";
    } else {
        $install_cmd = "install";
    }

    my $be_opts;
    if (defined $bename) {
        $be_opts = "--be-name " . $self->get_unique_be($beadm_list, $bename);
    } else {
        $be_opts = "--require-new-be";
    }
    $be_opts .= " --reject " . join(" --reject ", @$reject_keys)
        if @$reject_keys;
    $be_opts .= " --reject " . join(" --reject ", @$to_rm)
        if $to_rm and @$to_rm;

    my $line = "$install_cmd $be_opts " . join(' ', @$wanted_keys);
    print $fh "$line\n";
    $fh->close();

    if ($flagfile and ! $NoAction) {
        unless ($run_now) {
            #
            # Run spma-run in noaction mode to determine if anything
            # would be changed, so that the flagfile can be updated
            #
            $self->info("performing dry-run package install test");
            my $cmd = SPMA_RUN_NOACTION;
            push @$cmd, "--verbose" if $self->{LOGGER}{VERBOSE};
            if ($self->run_pkg_command($cmd, 1, SPMA_RUN_NO_CHANGES) == 0) {
                $fh = CAF::FileWriter->new($flagfile, log => $self,
                                           owner => $<, mode => 0644);
                $fh->close();
                $self->info("package changes are pending, " .
                            "use spma-run to query");
            } else {
                $self->info("no package changes are pending");
            }
        } else {
            $self->info("performing live package updates in new BE");
            my $cmd = SPMA_RUN_EXECUTE;
            push @$cmd, "--verbose" if $self->{LOGGER}{VERBOSE};
            if ($self->run_pkg_command($cmd, 1, SPMA_RUN_NO_CHANGES) == 0) {
                $self->info("package changes made in new BE");
            } else {
                $self->info("no package updates were required, " .
                            "no changes made");
            }
        }
    }

    return 1;
}

sub Configure
{
    my ($self, $config) = @_;

    #
    # We are parsing some outputs in this component.  We must set a
    # locale that we can understand.
    #
    local $ENV{LANG} = 'C';
    local $ENV{LC_ALL} = 'C';

#
# Commented out any code that deals with repos for now,
# on Solaris it may need to set-up the publishers in the future
#

#    my $repos = $config->getElement(REPOS_TREE)->getTree();
    my $t = $config->getElement(CMP_TREE)->getTree();

    #
    # Convert yes/no fields to boolean
    #
    $t->{run} = defined($t->{run}) && $t->{run} eq 'yes';
    $t->{userpkgs} = defined($t->{userpkgs}) && $t->{userpkgs} eq 'yes';

    #
    # Set default imagedir if required
    #
    my $imagedir = $t->{ips}->{imagedir};
    $imagedir = SPMA_IMAGEDIR unless defined($imagedir);

    #
    # Support $$ expansion in cmdfile, flagfile and imagedir
    # (chiefly needed by the unit tests)
    #
    my $cmdfile = $t->{cmdfile};
    my $flagfile = $t->{flagfile};
    $cmdfile =~ s/\$\$/$$/g;
    $flagfile =~ s/\$\$/$$/g;
    $imagedir =~ s/\$\$/$$/g;

    #
    # Merge software package requests from potentially multiple paths
    #
    my $merged_pkgs = $self->merge_pkg_paths($config, $t->{pkgpaths});
    my $merged_reject = $self->merge_pkg_paths($config, $t->{rejectpaths});
    my $merged_uninst = $self->merge_pkg_paths($config, $t->{uninstpaths});
    my $merged_whitelist = $self->merge_pkg_paths($config, $t->{whitepaths});
    $self->update_ips($merged_pkgs, $merged_reject, $merged_uninst,
                      $merged_whitelist, $t->{run},
                      $t->{userpkgs}, $cmdfile, $flagfile,
                      $t->{ips}->{bename}, $t->{ips}->{rejectidr},
                      $t->{ips}->{freeze}, $imagedir) or return 0;
    return 1;
}

sub Unconfigure
{
    my ($self, $config) = @_;

    if (-d SPMA_IMAGEDIR) {
        $self->info("removing " . SPMA_IMAGEDIR);
        rmtree(SPMA_IMAGEDIR) or die "cannot remove " .  SPMA_IMAGEDIR . ": $!";
    }
    return 1;
}

1; # required for Perl modules
