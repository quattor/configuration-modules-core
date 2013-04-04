# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::spma;
#
# a few standard statements, mandatory for all components
#
use strict;
use warnings;
use NCM::Component;
our $EC=LC::Exception::Context->new->will_store_all;
our @ISA = qw(NCM::Component);
use EDG::WP4::CCM::Element qw(unescape);

use CAF::Process;
use CAF::FileWriter;
use CAF::FileEditor;
use LC::Exception qw(SUCCESS);
use Set::Scalar;
use File::Path qw(mkpath);

use constant REPOS_DIR => "/etc/yum.repos.d";
use constant REPOS_TEMPLATE => "spma/repository.tt";
use constant REPOS_TREE => "/software/repositories";
use constant PKGS_TREE => "/software/packages";
use constant CMP_TREE => "/software/components/${project.artifactId}";
use constant YUM_CMD => qw(yum -y shell);
use constant RPM_QUERY => [qw(rpm -qa --qf %{NAME};%{ARCH}\n)];
use constant REMOVE => "remove";
use constant INSTALL => "install";
use constant YUM_PACKAGE_LIST => "/etc/yum/pluginconf.d/versionlock.list";
use constant LEAF_PACKAGES => [qw(package-cleanup --leaves --all --qf %{NAME};%{ARCH})];
use constant YUM_EXPIRE => qw(yum clean expire-cache);

use constant YUM_CONF_FILE => "/etc/yum.conf";
use constant CLEANUP_ON_REMOVE => "clean_requirements_on_remove";
use constant REPOQUERY => qw(repoquery --show-duplicates --envra);
use constant REPO_DEPS => qw(repoquery --resolve --requires --qf %{NAME};%{ARCH});
use constant YUM_COMPLETE_TRANSACTION => "yum-complete-transaction";
use constant OBSOLETE => "obsoletes";

our $NoActionSupported = 1;

# If user packages are not allowed, removes any repositories present
# in the system that are not listed in $allowed_repos.
sub cleanup_old_repos
{
    my ($self, $repo_dir, $allowed_repos, $allow_user_pkgs) = @_;

    return 1 if $allow_user_pkgs;

    my $dir;
    if (!opendir($dir, $repo_dir)) {
	$self->error("Unable to read repositories in $repo_dir");
	return 0;
    }

    my $current = Set::Scalar->new(map(m{(.*)\.repo$}, readdir($dir)));

    closedir($dir);
    my $allowed = Set::Scalar->new(map($_->{name}, @$allowed_repos));
    my $rm = $current-$allowed;
    foreach my $i (@$rm) {
	# We use $f here to make Devel::Cover happy
	my $f = "$repo_dir/$i.repo";
	$self->verbose("Unlinking outdated repository $f");
	if (!unlink($f)) {
	    $self->error("Unable to remove outdated repository $i: $!");
	    return 0;
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

# Generates the repository files in $repos_dir based on the contents
# of the $repos subtree. It uses Template::Toolkit $template to render
# the file. Optionally, proxy information will be used. In that case,
# it will use the $proxy host, wich is of $type "reverse" or
# "forward", and runs on the given $port.
sub generate_repos
{
    my ($self, $repos_dir, $repos, $template, $proxy, $type, $port) = @_;

    $proxy .= ":$port" if defined($port);


    foreach my $repo (@$repos) {
	my $fh = CAF::FileWriter->new("$repos_dir/$repo->{name}.repo",
				      log => $self);
	print $fh "# File generated by ", __PACKAGE__, ". Do not edit\n";
	if ($proxy) {
	    if ($type eq 'reverse') {
		$repo->{protocols}->[0]->{url} =~
		    s{^(.*?)://[^/]+(/?)}{$1://$proxy$2};
	    } elsif ($type eq 'forward') {
		$repo->{proxy} = $proxy;
	    }
	}
	my $rs = $self->template()->process($template, $repo, $fh);
	if (!$rs) {
	    $self->error ("Unable to generate repository $repo->{name}: ",
			  $self->template()->error());
	    $fh->cancel();
	    return 0;
	}
	$fh->close();
	$fh = CAF::FileWriter->new("$repos_dir/$repo->{name}.pkgs",
				   log => $self);
	print $fh "# Additional configuration for $repo->{name}\n";
	$fh->close();
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

sub execute_yum_command
{
    my ($self, $command, $why, $keeps_state, $stdin) = @_;

    my $cmd = CAF::Process->new($command, log => $self,
                                stdout => \my $out,
                                stdin => $stdin,
                                keeps_state => $keeps_state,
                                stderr => \my $err);

    $cmd->execute();

    if ($? || $err =~ m{^(Error:|Could not match)}m) {
        $self->error("Failed $why: $err");
        $self->warn("Command output: $out");
        return undef;
    }
    $self->warn("$why produced warnings: $err") if $err;
    $self->verbose("$why output: $out");
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

# Returns a set with the desired packages.
sub wanted_pkgs
{
    my ($self, $pkgs) = @_;

    my @pkl;

    while (my ($pkg, $st) = each(%$pkgs)) {
	my $name = unescape($pkg);
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
	@rs = ("distro-sync", @rs, "transaction run");
    } else {
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

    return defined($self->execute_yum_command([YUM_EXPIRE], "clean up caches"));
}

# Actually calls yum to execute transaction $tx
sub apply_transaction
{

    my ($self, $tx) = @_;

    $self->debug(5, "Running transaction: $tx");
    my $ok = $self->execute_yum_command([YUM_CMD], "running transaction", 1, $tx);
    return defined($ok);
}

# Lock the versions of any packages that have them
sub versionlock
{
    my ($self, $pkgs) = @_;

    my $locked = Set::Scalar->new();

    while (my ($pkg, $ver) = each(%$pkgs)) {
	my $name = unescape($pkg);
	while (my ($v, $a) = each(%$ver)) {
	    my $version = unescape($v);
	    foreach my $arch (keys(%{$a->{arch}})) {
		$locked->insert("$name-$version.$arch");
	    }
	}
    }

    my $out = $self->execute_yum_command([REPOQUERY, @$locked],
                                         "determining epochs", 1);
    return 0 if !defined($out);

    # Ensure that all the packages that we wanted to lock have been
    # resolved!!!
    foreach my $pkg (split(/\n/, $out)) {
	my @envra = split(/:/, $pkg);
	$locked->delete($envra[1]);
    }
    if (@$locked) {
	$self->error("Couldn't lock versions for $locked");
	return 0;
    }

    my $fh = CAF::FileWriter->new(YUM_PACKAGE_LIST, log => $self);
    print $fh "$out\n";
    $fh->close();
    return 1;
}

# Returns the set of packages to remove. A package must be removed if
# it is a leaf package and is not listed in $wanted, or if its
# architecture doesn't match the architectures specified in $wanted
# for that package.
sub packages_to_remove
{
    my ($self, $wanted) = @_;

    my $out = CAF::Process->new(LEAF_PACKAGES, keeps_state => 1,
                                log => $self)->output();

    if ($?) {
	$self->error ("Unable to find leaf packages");
	return;
    }

    # The leave set doesn't contain the header lines, which are just
    # garbage.
    my $leaves = Set::Scalar->new(grep($_ !~ m{\s}, split(/\n/, $out)));

    my $candidates = $leaves-$wanted;
    my $false_positives = Set::Scalar->new();
    foreach my $pkg (@$candidates) {
	my $name = (split(/;/, $pkg))[0];
	if ($wanted->has($name)) {
	    $false_positives->insert($pkg);
	}
    }

    return $candidates-$false_positives;
}

# Completes any pending transactions
sub complete_transaction
{
    my ($self) = @_;

    return defined($self->execute_yum_command([YUM_COMPLETE_TRANSACTION],
                                              "complete previous transactions"));
}

# Removes from $to_rm any packages that are depended on by any of the
# packages in $to_install.
#
# If any package in $to_install depended on anything in $to_rm we'd
# get a conflict when running the transaction.  We ensure this won't
# happen.
#
# It needs to call repoquery, and it might be slow during
# installations.
sub spare_dependencies
{
    my ($self, $to_rm, $to_install) = @_;

    return 1 if !$to_rm || !$to_install;
    my $cmd = CAF::Process->new([REPO_DEPS], log => $self,
				stdout => \my $deps, stderr => \my $err);

    foreach my $pkg (@$to_install) {
	$pkg =~ s{;}{.};
	$cmd->pushargs($pkg);
    }

    $cmd->execute();

    if ($? || $err =~ m{^Error:}m) {
	$self->error ("Couldn't check if the new packages depend on some ",
		      "package we might remove");
	return 0;
    }

    foreach my $dep (split("\n", $deps)) {
	$to_rm->delete($dep);
    }

    return 1;
}

# Updates the packages on the system.
sub update_pkgs
{
    my ($self, $pkgs, $run, $allow_user_pkgs) = @_;

    $self->complete_transaction() or return 0;

    my $installed = $self->installed_pkgs();
    defined($installed) or return 0;
    my $wanted = $self->wanted_pkgs($pkgs);

    $self->expire_yum_caches() or return 0;

    $self->versionlock($pkgs) or return 0;

    my ($tx, $to_rm, $to_install);

    $to_install = $wanted-$installed;

    if (!$allow_user_pkgs) {
	$to_rm = $self->packages_to_remove($wanted);
	defined($to_rm) or return 0;
	$self->spare_dependencies($to_rm, $to_install) or return 0;
	$tx = $self->schedule(REMOVE, $to_rm);
    }

    $tx .= $self->schedule(INSTALL, $to_install);

    $tx .= $self->solve_transaction($run);
    $self->apply_transaction($tx) or return 0;

    return 1;
}

# Set up a few things about Yum.conf. Somewhere in the future this may
# have its own schema, or be delegated to some other component. To be
# seen.
sub configure_yum
{
    my ($self, $cfgfile, $obsolete) = @_;
    my $fh = CAF::FileEditor->new($cfgfile, log => $self);

    $fh->add_or_replace_lines(CLEANUP_ON_REMOVE,
			      CLEANUP_ON_REMOVE. q{\s*=\s*1},
			      "\n" . CLEANUP_ON_REMOVE . "=1\n", ENDING_OF_FILE);
    $fh->add_or_replace_lines(OBSOLETE,
			      OBSOLETE . "\\s*=\\s*$obsolete",
			      "\n".  OBSOLETE. "=$obsolete\n", ENDING_OF_FILE);
    $fh->close();
}

sub Configure
{
    my ($self, $config) = @_;

    # We are parsing some outputs in this component.  We must set a
    # locale that we can understand.
    local $ENV{LANG} = 'C';
    local $ENV{LC_ALL} = 'C';

    my $repos = $config->getElement(REPOS_TREE)->getTree();
    my $t = $config->getElement(CMP_TREE)->getTree();
    # Convert these crappily-defined fields into real Perl booleans.
    $t->{run} = $t->{run} eq 'yes';
    $t->{userpkgs} = defined($t->{userpkgs}) && $t->{userpkgs} eq 'yes';
    my $pkgs = $config->getElement(PKGS_TREE)->getTree();
    $self->initialize_repos_dir(REPOS_DIR) or return 0;
    $self->cleanup_old_repos(REPOS_DIR, $repos, $t->{userpkgs}) or return 0;
    $self->generate_repos(REPOS_DIR, $repos, REPOS_TEMPLATE, $t->{proxyhost},
			  $t->{proxytype}, $t->{proxyport}) or return 0;
    $self->configure_yum(YUM_CONF_FILE, $t->{process_obsoletes});
    $self->update_pkgs($pkgs, $t->{run}, $t->{userpkgs})
	or return 0;
    return 1;
}

1; # required for Perl modules
