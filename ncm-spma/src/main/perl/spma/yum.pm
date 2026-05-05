# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::spma::yum;
#
# a few standard statements, mandatory for all components
#
use strict;
use warnings;
use NCM::Component;
our $EC=LC::Exception::Context->new->will_store_all;
our @ISA = qw(NCM::Component);
use EDG::WP4::CCM::Path 16.8.0 qw(unescape);
use EDG::WP4::CCM::TextRender;
use CAF::Process;
use CAF::FileWriter;
use CAF::FileEditor;
use LC::Exception qw(SUCCESS);
use Set::Scalar;
use File::Path qw(mkpath rmtree);
use Text::Glob qw(match_glob);
use File::Temp qw(tempdir);
use File::Copy;
use File::Basename;

use constant REPOS_DIR_DEFAULT => "/etc/yum.repos.d";
use constant REPOS_DIR_QUATTOR => "/etc/yum.quattor.repos.d";
use constant REPOS_TEMPLATE => "repository";
use constant REPOS_TREE => "/software/repositories";
use constant PKGS_TREE => "/software/packages";
use constant GROUPS_TREE => "/software/groups";
use constant RPM_QUERY => [qw(rpm -qa --qf %{NAME}\n%{NAME};%{ARCH}\n)];
use constant REMOVE => "remove";
use constant INSTALL => "install";
use constant YUM_PLUGIN_DIR => "/etc/yum/pluginconf.d";
use constant YUM_PACKAGE_LIST => YUM_PLUGIN_DIR . "/versionlock.list";
use constant LEAF_PACKAGES => [qw(package-cleanup --leaves --all --qf %{NAME};%{ARCH})];

use constant YUM_CONF_FILE => "/etc/yum.conf";
use constant YUM_COMPLETE_TRANSACTION => qw(yum-complete-transaction -y);

use constant SMALL_REMOVAL => 3;
use constant LARGE_INSTALL => 200;

use constant NOACTION_TEMPDIR_TEMPLATE => "/tmp/spma-noaction-XXXXX";

use constant YUM_CONF_CLEANUP_ON_REMOVE => "clean_requirements_on_remove";
use constant YUM_CONF_CLEANUP_ON_REMOVE_VALUE => 1;
use constant YUM_CONF_OBSOLETES => "obsoletes";
use constant YUM_CONF_PLUGINCONFPATH => 'pluginconfpath';
use constant YUM_CONF_REPOSDIR => 'reposdir';

# Must use cache (-C option)
use constant REPOGROUP => qw(repoquery -C -l -g --grouppkgs);
use constant REPOQUERY => qw(repoquery -C --show-duplicates);
use constant REPOQUERY_FORMAT => qw(--envra);
use constant REPO_DEPS => qw(repoquery -C --requires --resolve --plugins
                             --qf %{NAME};%{ARCH});
use constant REPO_WHATREQS => qw(repoquery -C --whatrequires --recursive --plugins
                                 --qf %{NAME}\n%{NAME};%{ARCH});

# Do not use cache (no -C option)
use constant YUM_EXPIRE => qw(yum clean expire-cache);
use constant YUM_PURGE_METADATA => qw(yum clean metadata);
use constant YUM_MAKECACHE => qw(yum makecache);
use constant YUM_CMD => qw(yum -y shell);
use constant YUM_DISTRO_SYNC => qw(yum -y distro-sync);

use constant VALID_PACKAGE_NAME => qr{^([\w\.\-\+]+)[*?]?};
use constant REPO_INCLUDE => 1;

our $NoActionSupported = 1;

# private variable to hold active noaction prefix
my $_active_noaction_prefix = "";

# set the active noaction prefix (method for unittesting)
sub __set_active_noaction_prefix
{
    my ($self, $prefix) = @_;
    $_active_noaction_prefix = $prefix;
    $self->verbose("Active noaction prefix set $_active_noaction_prefix") if ! $prefix;
}

# Given filename under NoAction=0, return the filename with proper NoAction prefix
sub _prefix_noaction_prefix
{
    my ($filename) = @_;
    return "$_active_noaction_prefix$filename";
}

# Basic test method for _match_noaction_tempdir
# Replaces X in the template with word regexp and see if it matches
# name has to be in the noaction tempdir, not just a prefix
sub __match_template_dir
{
    my ($self, $name, $template) = @_;
    # X is template for letter+digit+_, so \w is ok
    $template =~ s/X/\\w/g;
    $template .= '/' if ($template !~ m/\/$/);
    return $name =~ m/^$template/;
}

# Test if C<name> is under the NOACTION_TEMPDIR_TEMPLATE directory
sub _match_noaction_tempdir
{
    my ($self, $name) = @_;
    return $self->__match_template_dir($name, NOACTION_TEMPDIR_TEMPLATE);
}

sub cleanup_old_repos
{
    my ($self, $repo_dir, $allowed_repos, $action_cleanup) = @_;

    my @exts = qw(repo);
    push(@exts, 'pkgs') if ($self->REPO_INCLUDE);

    my $allowed = Set::Scalar->new(map($_->{name}, @$allowed_repos));

    return $self->_cleanup_old_something(
        $repo_dir, $allowed,
        "repository", \@exts,
        $action_cleanup
        );
}

# directory: directory to look for files
# allowed: set::scalar of names that will not be cleaned up
# type: what is being cleaned up (used in reporting)
# exts: arrayref of file extensions to cleanup up
# action_cleanup: boolean to cleanup old repositories when not running in NoAction.
#   Is considered true when not defined
sub _cleanup_old_something
{
    my ($self, $directory, $allowed, $type, $exts, $action_cleanup) = @_;

    my $types = $type;
    $types =~ s/y$/ie/;
    $types .= 's';

    if ($NoAction) {
        if ($self->_match_noaction_tempdir($directory)) {
            # This is ok
            $self->verbose("Going to remove $types from temporary NoAction",
                           " $type directory $directory.");
        } else {
            $self->error("Not going to cleanup $type files with NoAction",
                         " with unexpected $type directory $directory ",
                         " (expected template ", NOACTION_TEMPDIR_TEMPLATE, ").",
                         " Please report this issue to the developers,",
                         " as this is most likely a bug in the code.");
            # This is fatal
            return 0;
        }
    }

    # Test this after the NoAction bit for unittesting
    return 1 if defined($action_cleanup) && !$action_cleanup;

    my $dir;
    if (!opendir($dir, $directory)) {
        $self->error("Unable to read $types in $directory");
        return 0;
    }

    my $pattern = '(.*)\.(?:' . join('|', @$exts) . ')$';
    my $current = Set::Scalar->new(map(m{$pattern}, readdir($dir)));
    closedir($dir);

    my $rm = $current - $allowed;
    foreach my $i (@$rm) {
        foreach my $ext (@$exts) {
            my $fn = "$directory/$i.$ext";
            next if ! -e $fn;
            my $msg = "outdated $type $i (file $fn)";
            $self->verbose("Unlinking $msg");
            if (!unlink($fn)) {
                $self->error("Unable to remove $msg: $!");
                return 0;
            }
        }
    }
    return 1;
}

# Creates the repository dir if needed.
sub initialize_repos_dir
{
    my ($self, $repo_dir) = @_;
    if (! -d $repo_dir) {
        $self->verbose("$repo_dir didn't exist. Creating it");
        if (!eval{mkpath($repo_dir)} || $@) {
            $self->error("Unable to create repository dir $repo_dir: $@");
            return 0;
        }
    }
    return 1;
}

# Returns the URLs of the repositories listed in $prots, with their
# host part replaced by each of the reverse @proxies.
sub generate_reverse_proxy_urls
{
    my ($self, $prots, @proxies) = @_;

    my @l;
    foreach my $pt (@$prots) {
        foreach my $px (@proxies) {
            my $url = $pt->{url};
            $url =~ s{^(.*?):(/+)[^/]+}{$1:$2$px};
            push(@l, { url => $url });
        }
    }
    return \@l;
}

# Generate the URLs for the forward proxies, based on whether the
# repository is accessible over HTTP or HTTPS.
sub generate_forward_proxy_urls
{
    my ($self, $proto, @px) = @_;

    $proto->[0]->{url} =~ m{^(.*?):};
    return "$1://$px[0]";
}

# Generates the repository files in $repos_dir based on the contents
# of the $repos subtree. It uses Template::Toolkit $template to render
# the file. Optionally, proxy information will be used. In that case,
# it will use the $proxy host, wich is of $type "reverse" or
# "forward", and runs on the given $port.
# Returns undef on errors, or the number of repository files that were changed.
sub generate_repos
{
    my ($self, $repos_dir, $repos, $template, $proxy, $type, $port) = @_;

    my @px = split(",", $proxy) if $proxy;
    @px = map("$_:$port", @px) if $port;

    my $changes = 0;

    foreach my $repo (@$repos) {
        $repo->{repos_dir} = $repos_dir;
        if (!exists($repo->{proxy}) && @px) {
            if ($type eq 'reverse') {
                $repo->{protocols} = $self->generate_reverse_proxy_urls($repo->{protocols}, @px);
            } else {
                $repo->{proxy} = $self->generate_forward_proxy_urls($repo->{protocols}, @px);
            }
        }

        # No log instance passed, do all the logging ourself.
        $repo->{repo_include} = $self->REPO_INCLUDE;
        my $trd = EDG::WP4::CCM::TextRender->new($template, $repo, relpath => 'spma');
        if (! defined($trd->get_text())) {
            $self->error ("Unable to generate repository $repo->{name}: $trd->{fail}");
            return;
        };

        my $fh = $trd->filewriter($self->_keeps_state("$repos_dir/$repo->{name}.repo"),
                                  header => "# File generated by " . __PACKAGE__ . ". Do not edit",
                                  log => $self);
        $changes += $fh->close() || 0; # handle undef

        if ($self->REPO_INCLUDE) {
            $fh = CAF::FileWriter->new($self->_keeps_state("$repos_dir/$repo->{name}.pkgs"),
                                       log => $self);
            # TODO. Also add "do not edit" ? Or switch to FileEditor?
            print $fh "# Additional configuration for $repo->{name}\n";
            $fh->close();
        };
    }

    return $changes;
}

# Wrapper method to insert the yum configuration file to use
# Takes an arrayref as it would be passed to CAF::Process, assuming
# the first element is the executable
sub _set_yum_config
{
    my ($self, $cmd_ref) = @_;

    my ($exe, @args) = @$cmd_ref;

    my @new_cmd = ($exe, '-c', _prefix_noaction_prefix($self->YUM_CONF_FILE));
    push (@new_cmd, @args) if @args;

    return \@new_cmd;
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

sub execute_yum_command
{
    my ($self, $command, $why, $keeps_state, $stdin, $error_logger) = @_;

    $error_logger = "error" if (!($error_logger && $error_logger =~ m/^(error|warn|info|verbose)$/));

    my (%opts, $out, $err, @missing);

    %opts = ( log => $self,
          stdout => \$out,
          stderr => \$err,
          keeps_state => $keeps_state);

    $opts{stdin} = $stdin if defined($stdin);

    my $cmd = CAF::Process->new($self->_set_yum_config($command), %opts);

    $cmd->execute();
    if ($err) {
        # dnf always reports "Last metadata expiration check" to stderr, even if there's nothing wrong.
        # If that is the only message, we should not consider it to be a warning, and instead report it as verbose.
        my $warn_logger = ($err =~ m/\A[\s\n]*Last metadata expiration check.*[\s\n]*\z/m) ? 'verbose': 'warn';
        $self->$warn_logger("$why produced warnings: $err");
    }
    $self->verbose("$why output: $out") if(defined($out));
    if ($? ||
        ($err && $err =~ m{^\s*(
         Error |
         Failed (?! (?: \s+ (?: loading \s+ plugin \s+))) |
         (?:Could \s+ not \s+ match) |
         (?:Transaction \s+ encountered .* error) |
         (?:Unknown \s+ group \s+  package \s+ type) |
         (?:.*requested \s+ URL \s+ returned \s+ error) |
         (?:Versionlock \s* plugin) |
         (?:Command \s+ line \s+ error)
         )}oxmi) ||
        ($out && $out =~ m{^\s*(
         (?:[>]* \s* Problem (?: \s* \d+)? \s* :)  # from dnf transaction
         )}oxmi) ||
        ($out && (@missing = ($out =~ m{^No package (.*) available}omg)))
        ) {
        my $ec = $?;
        my $match = $1;
        $self->warn("Command output: $out");
        $self->$error_logger("Failed $why: ", $err || "(empty/undef stderr)");
        if (@missing) {
            $self->$error_logger("Missing packages: ", join(" ", @missing));
        } elsif (defined($match)) {
            $self->verbose("Command output match $match (exitcode $ec)");
        } else {
            $self->verbose("Command exitcode $ec");
        }
        return undef;
    }
    return $cmd->{NoAction} || $out;
}


# Returns a yum shell line for $op-erating on the $target
# packages. $op is typically "install" or "remove".
sub schedule
{
    my ($self, $op, $target) = @_;

    return "" if !@$target;

    my @ls;
    foreach my $pkg (@$target) {
        push(@ls, $pkg);
        $ls[-1] =~ s{;}{.};
    }
    return  sprintf("%s %s\n", $op, join(" ", @ls));
}

# Returns a set of all installed packages
sub installed_pkgs
{
    my $self = shift;

    my $cmd = CAF::Process->new(RPM_QUERY, keeps_state => 1,
                log => $self);

    my $out = $cmd->output();
    if ($?) {
        return undef;
    }
    # We don't consider gpg-pubkeys, which won't come from any
    # downloaded RPM, anyways.
    my @pkgs = grep($_ !~ m{^gpg-pubkey.*\(none\)$}, split(/\n/, $out));

    return Set::Scalar->new(@pkgs);
}

# Returns the set of packages in all the $groups passed as arguments,
# or undef if ANY of the groups cannot be expanded.  For now it calls
# repoquery once per group.  I hope there will be few enough groups in
# the profile so that this isn't a performance bottleneck.
sub expand_groups
{
    my ($self, $groups) = @_;

    my $pkgs = Set::Scalar->new();

    while (my ($group, $types) = each(%$groups)) {
        my $what = join(",", grep($types->{$_}, keys(%$types)));
        my $lst = $self->execute_yum_command([REPOGROUP, $what, $group],
                                             "Group expansion", 1)
            or return undef;
        $pkgs->insert(split(/\n/, $lst));
    }
    return $pkgs;
}

# Given a hashref of packages, return arrayref with all packages
# when all have sane/valid package names; undef (and reports error) otherwise.
# If adddata is true, also add the data as arrayref tuple (2 element arrayref instead of package name)
sub valid_packages
{
    my ($self, $pkgs, $adddata) = @_;

    my @ok;
    foreach my $escpkg (sort keys %$pkgs) {
        my $pkg = unescape($escpkg);
        if ($pkg =~ VALID_PACKAGE_NAME) {
            push(@ok, $adddata ? [$1, $pkgs->{$escpkg}] : $1);
        } else {
            $self->error("Invalid package name: $pkg");
            return;
        }
    }

    return \@ok;
}

# Returns a set with the desired packages.
# Package names pre-validated
sub wanted_pkgs
{
    my ($self, $escpkgs) = @_;

    my $pkgs = $self->valid_packages($escpkgs, 1) or return;
    my @pkl;


    foreach my $pkg (@$pkgs) {
        my ($name, $st) = (@$pkg);

        if (%$st) {
            while (my ($ver, $archs) = each(%$st)) {
                push(@pkl, map("$name;$_", keys(%{$archs->{arch}})));
            }
        } else {
            push(@pkl, $name);
        }
    }
    return Set::Scalar->new(@pkl);
}

# Returns the yum shell command to apply the transaction. If run, the
# transaction will be applied. Otherwise it will just be solved and
# printed.
sub solve_transaction {
    my ($self, $run) = @_;

    my @rs = "transaction solve";
    if ($run && !$NoAction) {
        push(@rs, "transaction run");
    } else {
        $self->verbose("Resetting transaction with NoAction=1 (instead of running it)")
            if ($NoAction);
        push(@rs, "transaction reset");
    }
    return join("\n", @rs, "");
}

# Expires Yum caches before modifying the system.  Failure to do so
# would lead to recent packages not being seen or installed during the
# execution.  In the worst case, the package is an upgrade to an
# existing one, and either the old version is left around, or even
# worse, the old version is removed and the new version is not
# installed at all.
sub expire_yum_caches
{
    my ($self) = @_;

    # this only affects the caches, can be safely expired/cleaned up
    return defined($self->execute_yum_command([YUM_EXPIRE], "clean up caches", 1));
}

# Actually calls yum to execute transaction $tx
sub apply_transaction
{

    my ($self, $tx, $error_is_warn) = @_;

    $self->debug(5, "Running transaction: $tx");
    my $ok = $self->execute_yum_command([YUM_CMD], "running transaction", 1,
                                        $tx, $error_is_warn ? "warn" : "error");
    return defined($ok);
}

# Prepares two sets of stuff to versionlock, from the escaped
# structure in $pkgs.  Returns a set with the package names that need
# to be versionlocked, and a reference to a list to be passed to
# repoquery.
#
# The set has the * globs removed from the package names, to fix issue
# #100.  It doesn't remove them from the versions, so that we can
# still lock stuff like "any available python 2.7 (but not the
# 2.4.x!!)
sub prepare_lock_lists
{
    my ($self, $pkgs) = @_;

    my $locked = Set::Scalar->new();

    my $toquery = [];

    while (my ($pkg, $ver) = each(%$pkgs)) {
        my $name = unescape($pkg);
        my $gn = $name;
        $gn =~ s{\*}{}g;
        while (my ($v, $a) = each(%$ver)) {
            my $version = unescape($v);
            next if $version eq '*';
            foreach my $arch (keys(%{$a->{arch}})) {
                $locked->insert("$gn-$version.$arch");
                push(@$toquery, "$name-$version.$arch");
            }
        }
    }

    return ($locked, $toquery);
}

# generate a msg for logging purposes based on
# wanted_locked and not_matched (passed as ref here)
# The message can be long because it contains list of
# all packages and non-exact matched repoquery output
# Lists are not comma separated so it can be copied
# and used on command line
sub _make_msg_wanted_locked
{

    my ($wanted_locked, $not_matched_ref) = @_;

    return sprintf(
        "%d wanted packages with wildcards: %s, ".
        "%d non-exact matched packages from repoquery: %s",
        $wanted_locked->size, join(" ", @$wanted_locked),
        scalar @$not_matched_ref, join(" ", @$not_matched_ref)
        );

}

# Returns whether the $locked string locks all the items in
# $wanted_locked.  Warning: $wanted_locked will be modified!!
# ($locked is output from REPOQUERY).
# When C<fullsearch> is true, the result will be checked
# for with glob pattern matching to verify the requested packages
# are in the $locked string. Otherwise, any requested package with
# a wildcard will be assumed to have a match in the output.
# The main issue with fullsearch is that it is a possibly slow process.
sub locked_all_packages
{
    my ($self, $wanted_locked, $locked, $fullsearch) = @_;

    my @not_matched;

    # Process output and filter exact matches
    foreach my $pkgstr (split(/\n/, $locked)) {
        my @envra = split(/:/, $pkgstr);
        if (scalar @envra != 2) {
            $self->error("no epoch in repoquery format '", join(" ", REPOQUERY_FORMAT), "' for $pkgstr");
            return;
        }

        # in nevra format, remove the trailing epoch
        # (in envra, removing the trailing epoch reduces it to empty string)
        my $noepoch = $envra[0];
        $noepoch =~ s/\d+$//;

        my $pkg = $noepoch.$envra[1];
        if ($wanted_locked->has($pkg)) {
            $wanted_locked->delete($pkg);
        } else {
            # keep repoquery output of non-exact matched packages
            # locked packages like kernel*-some.version will cause other
            # entries like kernel-devel in the repoquery output, which
            # will never match, so having packages in @not_locked.
            push(@not_matched, $pkg) if $pkg;
        }
    }

    # No wanted_locked packages left, everything matched
    if (! @$wanted_locked) {
        $self->verbose("All wanted_locked packages found (without any wildcard processing).");
        return 1;
    }

    my $msg = _make_msg_wanted_locked($wanted_locked, \@not_matched);
    if ($fullsearch) {
        # At this point, all remaining entries in the wanted_locked
        # might have a wildcard in them.
        # Brute-force could possibly lead to a very slow worst case scenario
        #
        # Issue: single wildcard might match multiple lines of output,
        #   so always process all output
        $self->verbose("Starting fullsearch on $msg.");
        foreach my $wl (@$wanted_locked) {
            # (try to) match @not_matched
            # TODO: remove the matches? can we assume that every
            #  match corresponds to exactly one wildcard? probably not.
            #  e.g. a-*5 will match a-6.5, but also a-devel-6.5; so a-devel-*5
            #  would be left without (valid) match.
            #  -> current implementation does not remove the matches.
            $wanted_locked->delete($wl) if (grep(match_glob($wl, $_), @not_matched));
        }

        $msg = "wanted_locked packages found (with fullsearch wildcard processing)." .
            "Finished fullsearch with " .
            _make_msg_wanted_locked($wanted_locked, \@not_matched);
        if (@$wanted_locked) {
            $self->error("Not all $msg.");
            return 0;
        } else {
            $self->verbose("All $msg.");
            return 1;
        }
    } elsif (grep($_ !~ m{[*?]}, @$wanted_locked)) {
        $self->error("Unable to lock all packages. ",
                     "These packages with these versions don't seem to exist ",
                     "in any configured repositories. $msg.");
        return 0;
    } elsif (grep($_ =~ m{[*?]}, @$wanted_locked)) {
        # actually, only wildcards in the versions
        $self->info("Unsure if all wanted packages are avaialble ",
                    "due to wildcard(s) in the names and/or versions, ",
                    "continuing as if all is fine. ",
                    "Turn on fullsearch option to resolve the wildcards ",
                    "(but be aware of potential speed impact: $msg).");
        return 1;
    }

    # how do we get here?
    return 1;
}

# Lock the versions of any packages that have them
sub versionlock
{
    my ($self, $pkgs, $fullsearch) = @_;

    my ($locked, $toquery) = $self->prepare_lock_lists($pkgs);
    my $out = $self->execute_yum_command([REPOQUERY, $self->REPOQUERY_FORMAT, @$toquery],
                                         "determining epochs", 1);
    return 0 if !defined($out) || !$self->locked_all_packages($locked, $out, $fullsearch);


    my $fh = CAF::FileWriter->new($self->_keeps_state(_prefix_noaction_prefix(YUM_PACKAGE_LIST)),
                                  log => $self);
    print $fh "$out\n";
    $fh->close();
    return 1;
}

# return package to remove
#   candidates are (non-trivial) values from the leaves selection command (name;arch format)
#   wanted is list of packages that spma should install (name and also name;arch format)
sub _pkg_rem_calc
{
    my ($self, $candidates, $wanted) = @_;

    my $false_positives = Set::Scalar->new();
    foreach my $pkg (@$candidates) {
        my $name = (split(/;/, $pkg))[0];
        if ($wanted->has($name)) {
            $false_positives->insert($pkg);
        }
    }

    return $candidates - $false_positives;
};


# Returns the set of packages to remove. A package must be removed if
# it is a leaf package and is not listed in $wanted, or if its
# architecture doesn't match the architectures specified in $wanted
# for that package.
sub packages_to_remove
{
    my ($self, $wanted) = @_;

    my $out = CAF::Process->new($self->_set_yum_config($self->LEAF_PACKAGES),
                                keeps_state => 1,
                                log => $self)->output();

    if ($?) {
        $self->error ("Unable to find leaf packages");
        return;
    }

    # The leaf set doesn't contain the header lines, which are just
    # garbage.
    my $leaves = Set::Scalar->new(grep($_ !~ m{\s}, split(/\n/, $out)));

    my $candidates = $leaves - $wanted;

    return $self->_pkg_rem_calc($candidates, $wanted);
}

# Queries for packages packages that depend on $rm, and if there is a
# match in $install, it removes the $rm entry.
sub spare_deps_whatreq
{
    my ($self, $rm, $install, $error_is_warn) = @_;

    my @to_rm;

    foreach my $pk (@$rm) {
        my $arg = $pk;
        $arg =~ s{;}{.};
        my $whatreqs = $self->execute_yum_command([$self->REPO_WHATREQS, $arg],
                                                  "determine what requires $pk", 1,
                                                  undef, $error_is_warn ? "warn" : "error");
        return 0 if !defined($whatreqs);
        foreach my $wr (split("\n", $whatreqs)) {
            if ($install->has($wr)) {
                push(@to_rm, $pk);
            }
        }
    }

    $rm->delete(@to_rm);
    return 1;
}


# Queries for all the dependencies of the packages in $install and
# removes them from $rm.
sub spare_deps_requires
{
    my ($self, $rm, $install, $error_is_warn) = @_;

    my (@pkgs);

    foreach my $pkg (@$install) {
        $pkg =~ s{;}{.};
        push(@pkgs, $pkg);
    }

    my $deps = $self->execute_yum_command([$self->REPO_DEPS, @pkgs],
                                          "dependencies of install candidates", 1,
                                          undef, $error_is_warn ? "warn" : "error");

    return 0 if !defined $deps;

    foreach my $dep (split("\n", $deps)) {
       $rm->delete($dep);
    }

    return 1;
}

# Removes from $rm any packages that are depended on by any of the
# packages in $install.
#
# If any package in $install depended on anything in $rm we'd
# get a conflict when running the transaction.  We ensure this won't
# happen.
#
# It needs to call repoquery, and on large transactions that may be
# slow.  That's why we try to optimise the easy case where there is
# almost nothing to remove and a lot of new things to add.
sub spare_dependencies
{
    my ($self, $rm, $install, $error_is_warn) = @_;

    return 1 if (!$rm || !$install);

    # The whatreq path seems to have *cubic* cost!! It's still a big
    # speedup for installations, where we want to remove almost
    # nothing and may want to install and upgrade quite a lot of
    # things.
    if (scalar(@$rm) < SMALL_REMOVAL && scalar(@$install) > LARGE_INSTALL) {
        $self->debug(3, "Sparing dependencies in the whatreq path");
        return $self->spare_deps_whatreq($rm, $install, $error_is_warn);
    } else {
        $self->debug(3, "Sparing dependencies in the requires path");
        return $self->spare_deps_requires($rm, $install, $error_is_warn);
    }
}


# Completes any pending transactions
sub _do_complete_transaction {
    my ($self) = @_;
    return defined($self->execute_yum_command([YUM_COMPLETE_TRANSACTION],
                                              "complete previous transactions"));
}

sub complete_transaction
{
    my ($self) = @_;

    if ($NoAction) {
        # not completing outstanding transactions
        # should be ok to ignore for queries (i.e. NoAction)
        # TODO: check if there's a way to test if anything is outstanding,
        # and only continue if all is fine
        $self->verbose("Skipping complete_transaction in NoAction mode");
        return 1;
    } else {
        return $self->_do_complete_transaction();
    }
}

# Purges the Yum repository caches.  For now we only care about the
# metadata, in order to avoid re-downloading re-installed packages.
sub purge_yum_caches
{
    my ($self) = @_;

    # This only affects the caches, can be safely purged
    return defined($self->execute_yum_command([YUM_PURGE_METADATA],
                                              "purge repository metadata",
                                              1));
}

# Create the yum cache
sub make_cache
{
    my ($self) = @_;

    # This only affects the caches, can be safely created
    return defined($self->execute_yum_command([YUM_MAKECACHE],
                                              "create yum cache",
                                              1));
}

# Runs yum distro-sync.  Before modifying the installed sets we must
# align the system to the repositories.  Otherwise we'll get a lot of problems.
sub distrosync
{
    my ($self, $run, $pkgs) = @_;

    my @cmd = (YUM_DISTRO_SYNC);
    if ($pkgs) {
        push (@cmd, @$pkgs);
        $self->verbose("distro-sync with packages @$pkgs");
    } else {
        $self->verbose("distro-sync without any package restriction");
    }

    if (!$run) {
        $self->info("Skipping @cmd");
        return 1;
    }

    return $self->execute_yum_command(\@cmd, "synchronisation with upstream".($pkgs ? " packages @$pkgs" : ''));
}

# Updates the packages on the system.
sub update_pkgs
{
    my ($self, $allpkgs, $groups, $run, $allow_user_pkgs, $purge,
        $error_is_warn, $fullsearch, $reuse_cache, $pkgs) = @_;

    # default/undef means everything
    my $distrosyncpkgs;
    if (defined($pkgs)) {
        $distrosyncpkgs = $self->valid_packages($pkgs) or return;
    } else {
        $pkgs = $allpkgs;
    }

    $self->complete_transaction() or return 0;

    if (! $reuse_cache) {
        my $clean_cache_method = ($purge ? 'purge' : 'expire') . "_yum_caches";
        $self->$clean_cache_method() or return 0;

        $self->make_cache() or return 0;
    };

    # Versionlock is determined based on all configured packages
    $self->versionlock($allpkgs, $fullsearch) or return 0;

    $self->distrosync($run, $distrosyncpkgs) or return 0;

    my $group_pkgs = $self->expand_groups($groups);
    defined($group_pkgs) or return 0;

    my $wanted_pkgs = $self->wanted_pkgs($pkgs);
    defined($wanted_pkgs) or return 0;

    my $wanted = $group_pkgs + $wanted_pkgs;

    my $installed = $self->installed_pkgs();
    defined($installed) or return 0;

    my ($tx, $to_rm, $to_install);

    $to_install = $wanted-$installed;

    if (!$allow_user_pkgs) {
        $to_rm = $self->packages_to_remove($wanted);
        defined($to_rm) or return 0;
        $self->spare_dependencies($to_rm, $to_install, $error_is_warn);
        $tx = $self->schedule(REMOVE, $to_rm);
    }

    $tx .= $self->schedule(INSTALL, $to_install);

    if ($tx) {
        $tx .= $self->solve_transaction($run);
        $self->apply_transaction($tx, $error_is_warn) or return 0;
    }

    return 1;
}

# Updates the packages on the system.
sub update_pkgs_retry
{
    my ($self, $allpkgs, $groups, $run, $allow_user_pkgs, $purge,
        $retry_if_not_allow_user_pkgs, $fullsearch, $pkgs) = @_;

    # If an error is logged due to failed transaction (or spare dependencies),
    # it might be retried and might succeed, but ncm-ncd will not allow
    # any component that has spma as dependency (i.e. typically all others)
    # to run (becasue he initial attempt had an error)
    my $error_is_warn = $retry_if_not_allow_user_pkgs && ! $allow_user_pkgs;

    # Introduce shortcut to call update_pkgs with the same except 2 arguments
    my $update_pkgs = sub {
        my ($allow_user_pkgs, $error_is_warn, $reuse_cache) = @_;
        return $self->update_pkgs($allpkgs, $groups, $run, $allow_user_pkgs, $purge,
                                  $error_is_warn, $fullsearch, $reuse_cache, $pkgs);
    };

    # Only on the initial try, purge and recreate the cache
    if (&$update_pkgs($allow_user_pkgs, $error_is_warn, 0)) {
        $self->verbose("update_pkgs ok");
    } else {
        if ($NoAction) {
            # There's no point in retrying, each attemp will have the transaction reset instead of run.
            $self->verbose("update_pkgs ended with NoAction=1");
            return 1;
        } elsif ($allow_user_pkgs) {
            # error_is_warn = 0 in this case, error is already logged
            $self->verbose("update_pkgs failed, userpkgs=true");
            return 0;
        } elsif ($retry_if_not_allow_user_pkgs) {
            # all tx failures are errors here
            $error_is_warn = 0;

            $self->verbose("userpkgs_retry: 1st update_pkgs failed, going to retry with forced userpkgs=true");
            $allow_user_pkgs = 1;
            if(&$update_pkgs($allow_user_pkgs, $error_is_warn, 1)) {
                $self->verbose("userpkgs_retry: 2nd update_pkgs with forced userpkgs=true ok, trying 3rd");
                $allow_user_pkgs = 0;
                if(&$update_pkgs($allow_user_pkgs, $error_is_warn, 1)) {
                    $self->verbose("userpkgs_retry: 3rd update_pkgs with userpkgs=false ok.");
                } else {
                    $self->error("userpkgs_retry: 3rd update_pkgs with userpkgs=false failed.");
                    return 0;
                };
            } else {
                $self->error("userpkgs_retry: 2nd update_pkgs with forced userpkgs=true failed.");
                return 0;
            };
        } else {
            # log failure, no retry enabled
            # error_is_warn = 0 in this case, error is already logged
            $self->verbose("update_pkgs failed, userpkgs=false, no retry enabled");
            return 0;
        }
    }

    return 1;
};


# keeps_state checks if files keep state or not.
# in particular, all files that match the tempdir keeps state
# Returns array of filename and then option keeps_state
#   to be used in filewriter create
sub _keeps_state
{
    my ($self, $filename) = @_;

    my $keeps_state = $self->_match_noaction_tempdir($filename) ? 1 : 0;
    $self->verbose("File $filename does", ($keeps_state ? "" : " not"),
                   " keep state (template ", NOACTION_TEMPDIR_TEMPLATE, ")");

    return ($filename, keeps_state => $keeps_state);
}


# copy file(s) and (non-recursively) directories to prefix
# preserving the directory tree structure.
# e.g. /etc/yum.conf and prefix /tmp/mytemp will result in
# /tmp/mytemp/etc/yum.conf.
# return 1 in case of success, undef in case of failure. the method logs errors
# TODO: replace by something else
sub _copy_files_and_dirs
{
    my ($self, $prefix, @data) = @_;

    foreach my $data (@data) {
        my ($destdir, @files);

        if (-f $data) {
            $destdir = $prefix."/".dirname($data);
            # using basename is ok here since we tested if it is a file
            push(@files, basename($data));

            # set $data to the directory
            $data = dirname($data);
        } elsif (-d $data) {
            $destdir = "$prefix/$data";
            my $dir;
            if (! opendir($dir, $data)) {
                $self->error("Can't opendir $data: $!");
                return;
            };
            # only copy files (and ignore e.g. . and ..)
            push(@files, grep {-f "$data/$_" } readdir($dir));
            if (! closedir($dir)) {
                $self->error("Can't closedir $data: $!");
                return;
            }
        } elsif (! -e $data) {
            $self->error("Can't copy non-existing $data.");
            return;
        } else {
            $self->error("Don't know how to copy $data to the prefix $prefix.");
            return;
        }

        # mkpath in scalar context returns number of diretcories actually created
        if(! ($destdir && (-d $destdir || mkpath($destdir)))) {
            $self->error("Failed to create destdir $destdir (for data $data): ec $?");
            return;
        };
        foreach my $filename_taint (@files) {
            my $filename;
            # untainting check for newlines
            if ($filename_taint =~ m/^(.+)$/) {
                $filename = $1;
            } else {
                $self->error("Failed to untaint $filename_taint");
                return;
            }

            if(! ($filename && copy("$data/$filename", "$destdir/$filename"))) {
                $self->error("Failed to copy $data/$filename to $destdir/$filename: $!");
                return;
            };
        }
        $self->verbose("Copied files from $data to $destdir: ", join(",", @files));
    }

    return 1;
}

# Return the prefix to use for all configuration, plugin and repository paths.
# When noaction is false, no prefix is used and empty string is returned.
# If noaction is true, a temporary directory is created and the path returned.
# In case of an error, an error is logged and undef is returned.
# All other arguments are either files or directories that copied in the temporary
# directory.
sub noaction_prefix
{
    my ($self, $noaction, @data) = @_;

    my $tmppath;
    if ($noaction) {
        # Create temporary directory
        $tmppath = tempdir(NOACTION_TEMPDIR_TEMPLATE);

        # Set strict permissions
        if (! chmod(0700, $tmppath)) {
            $self->error("Failed to chmod 0700 tmp yum dir $tmppath: $!");
            return;
        }

        # Make sure the returned path ends with a /
        $tmppath .= "/" if ($tmppath !~ m/\/$/);

        return if (! $self->_copy_files_and_dirs($tmppath, @data));

        $self->verbose("Created noaction prefix $tmppath.");

    } else {
        # Do nothing, return empty string without noaction
        $self->debug(1, "Nothing to do for noaction prefix.");
        $tmppath = '' ;
    }

    $self->__set_active_noaction_prefix($tmppath);

    return $tmppath;
}

# Set up a few things about Yum.conf. Somewhere in the future this may
# have its own schema, or be delegated to some other component. To be
# seen.
# C<repodirs> is an arrayref of directories.
sub configure_yum
{
    my ($self, $cfgfile, $obsoletes, $plugindir, $repodirs, $extra_opts) = @_;

    my $fh = CAF::FileEditor->new($self->_keeps_state($cfgfile), log => $self);

    my $_add_or_replace = sub {
        my ($fh, $name, $value) = @_;
        my $valuereg = $value;
        $valuereg =~ s/([.\$*?])/\\$1/g;
        $fh->add_or_replace_lines(
            $name,
            $name. q{\s*=\s*}.$valuereg.'$',
            "$name=$value\n",
            ENDING_OF_FILE
        );
    };

    # use CONSTANT() to get the value of the constant as key
    my $yum_opts = {
        YUM_CONF_CLEANUP_ON_REMOVE() => $self->YUM_CONF_CLEANUP_ON_REMOVE_VALUE(),
        YUM_CONF_OBSOLETES() => $obsoletes,
        YUM_CONF_REPOSDIR() => $repodirs,
        YUM_CONF_PLUGINCONFPATH() => $plugindir,
    };

    # Merge the options, yum_opts precede.
    $extra_opts = {} if (! defined($extra_opts));
    my %opts = (%$extra_opts, %$yum_opts);

    foreach my $key (sort keys %opts) {
        my $v = $opts{$key};
        my $value = ref($v) eq 'ARRAY' ? join(($key eq 'exclude') ? ' ' : ',', @$v) : $v;
        $_add_or_replace->($fh, $key, $value);
    };

    $fh->close();

}

# Configure the yum plugins
sub configure_plugins
{
    my ($self, $plugindir, $plugins) = @_;

    # Sanity checks
    # versionlock plugin: enable by default
    my $packagelist = _prefix_noaction_prefix(YUM_PACKAGE_LIST);
    if ($plugins->{versionlock}) {
        # TODO: check and warn for disabled versionlock plugin?
        # versionlock plugin: locklist is mandatory in schema
        if ($plugins->{versionlock}->{locklist} ne $packagelist) {
            $self->warn("yum plugin versionlock plugin unsupported locklist $plugins->{versionlock}->{locklist}. ",
                        "Forcing it to $packagelist.");
            $plugins->{versionlock}->{locklist} = $packagelist;
        }
    } else {
        $self->verbose("yum plugin versionlock is not configured. Will be enabled.");
        $plugins->{versionlock} = {
            enabled => 1,
            locklist => $packagelist,
        };
    }

    # disable by default
    foreach my $name (qw(fastestmirror subscription-manager product-id)) {
        if (! $plugins->{$name}) {
            $self->verbose("yum plugin $name is not configured. It will be disabled.");
            $plugins->{$name}->{enabled} = 0;
        }
    }

    # priorities plugin: enable by default
    if (! $plugins->{priorities}) {
        $self->verbose("yum plugin priorities is not configured. It will be enabled.");
        $plugins->{priorities}->{enabled} = 1;
    }

    my $changes = 0;
    foreach my $plugin (sort keys %$plugins) {
        $self->verbose("Going to configure plugin $plugin.");
        my $plugin_config = $plugins->{$plugin};
        # insert plugindir for TT purposes
        $plugin_config->{"_plugindir"} = $plugindir;

        my $trd = EDG::WP4::CCM::TextRender->new(
            "yumplugins/$plugin",
            $plugin_config,
            relpath => 'spma',
            log => $self);

        if (! defined($trd->get_text())) {
            $self->error ("Unable to generate yum plugin $plugin config: $trd->{fail}");
            return;
        };

        # returns undef on render error, the error is logged
        my $fh = $trd->filewriter($self->_keeps_state("$plugindir/$plugin.conf"));

        if(defined $fh) {
            $changes += $fh->close() || 0; # handle undef
        }
    }

    return $changes;
}

# nothing to do for yum. this is dnf only
sub modularity { return 1;};

sub Configure
{
    my ($self, $config) = @_;

    # We are parsing some outputs in this component.  We must set a
    # locale that we can understand.
    local $ENV{LANG} = 'C';
    local $ENV{LC_ALL} = 'C';

    my ($purge_caches, $res);

    my $t = $config->getTree($self->prefix());
    # Convert these crappily-defined fields into real Perl booleans.
    $t->{run} = $t->{run} eq 'yes';

    my $userpkgs_defined = defined($t->{userpkgs});
    $t->{userpkgs} = $userpkgs_defined && ($t->{userpkgs} eq 'yes');

    # When userpkgs are allowed, there is no control over what is in the reposdir
    # If they are not allowed, and retry is allowed, use a non-standard location
    # to avoid any repositories getting added during the retries (e.g. from rpms).
    my $main_repos_dir = ($NoAction || $t->{userpkgs} || (!$t->{userpkgs_retry})) ?
                             REPOS_DIR_DEFAULT : REPOS_DIR_QUATTOR;

    my $repos = $config->getTree(REPOS_TREE);
    my $allpkgs = $config->getTree(PKGS_TREE);
    my $groups = $config->getTree(GROUPS_TREE) || {};

    # packages to install; undef means allpkgs will be installed
    my $pkgs;
    if (exists($t->{filter})) {
        # only define this here, should not affect selection of the main_repos_dir
        if (! $userpkgs_defined) {
            # continue in userpkgs mode
            $t->{userpkgs} = 1;
            # enable repository cleanup
            $t->{repository_cleanup} = 1 if ! defined($t->{repository_cleanup});
        }
        local $@;
        my $regex;
        eval {
            $regex = qr{$t->{filter}};
        };
        if ($@) {
            $self->error("filter $t->{filter} is not a valid pattern: $@");
            return 0;
        }
        $pkgs = {map {$_ => $allpkgs->{$_}} grep {unescape($_) =~ m/$regex/} sort keys %$allpkgs};
        $self->verbose("packages filtered with pattern $t->{filter}: kept ",
                       scalar keys %$pkgs, " of all ", scalar keys %$allpkgs, " packages");
    } else {
        $self->verbose("No packages filtered");
    }

    # check if a temp location is required for NoAction support.
    my $prefix = $self->noaction_prefix($NoAction, YUM_PLUGIN_DIR, $main_repos_dir, $self->YUM_CONF_FILE);

    if (! defined($prefix)) {
        return 0;
    } elsif ($NoAction && ! $self->_match_noaction_tempdir("$prefix/")) {
        # extra safety check
        $self->error("Noaction prefix in NoAction has to start with template ",
                     NOACTION_TEMPDIR_TEMPLATE, " (prefix $prefix).");
        return 0;
    };

    # TODO: is this fatal or not?
    # TODO: should this also influence purge_caches?
    #       (if it does, the "defined($purge_caches) or return 0;" test has to be modified)
    # always run it, even if no plugins configured (e.g. to disable fastest mirror)
    my $plugindir = _prefix_noaction_prefix(YUM_PLUGIN_DIR);
    $res = $self->configure_plugins($plugindir, $t->{plugins});
    defined($res) or return 0;
    $purge_caches = $res;

    my $quattor_managed_reposdir = _prefix_noaction_prefix($main_repos_dir);
    $self->initialize_repos_dir($quattor_managed_reposdir) or return 0;

    # Unless explicitly allowed or when user packages are not allowed,
    # removes any repositories present in the system that are not listed in $allowed_repos.
    $t->{repository_cleanup} = !$t->{userpkgs} if ! defined($t->{repository_cleanup});
    $self->cleanup_old_repos($quattor_managed_reposdir, $repos, $t->{repository_cleanup}) or return 0;

    $res = $self->generate_repos($quattor_managed_reposdir, $repos, REPOS_TEMPLATE,
                                 $t->{proxyhost}, $t->{proxytype}, $t->{proxyport});

    $self->modularity($t->{modules}, $config) or return 0;

    defined($res) or return 0;
    $purge_caches += $res;

    # by default, set the quattor managed repos dir
    # TODO: for userpkgs, insert quattor unmanaged dir as first (so it takes priority)
    # TODO: check that the first one wins
    my $reposdir = [$quattor_managed_reposdir];
    if ($t->{reposdirs}) {
        push(@$reposdir, @{$t->{reposdirs}});
    }
    $self->configure_yum(_prefix_noaction_prefix($self->YUM_CONF_FILE),
                         $t->{process_obsoletes}, $plugindir, $reposdir, $t->{main_options});

    $res = $self->update_pkgs_retry($allpkgs, $groups, $t->{run},
                                    $t->{userpkgs}, $purge_caches, $t->{userpkgs_retry},
                                    $t->{fullsearch}, $pkgs);

    my $ec = 1;

    # Cleanup prefix in case of success.
    # Leave in case of failure (to help debugging)
    if ($res) {
        if ($NoAction) {
            if(rmtree($prefix)) {
                $self->info("Cleaning up NoAction prefixdir $prefix");
            } else {
                $self->warn("Failed to cleanup NoAction prefixdir $prefix: $!");
                # Not going to let spma fail for this.
            };
        }
    } else {
        $self->info("Not cleaning up NoAction prefixdir $prefix") if $prefix;
        $ec = 0;
    }

    return $ec;
}

1; # required for Perl modules
