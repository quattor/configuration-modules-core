#${PMpre} NCM::Component::spma::apt${PMpost}

use Data::Dumper;
$Data::Dumper::Indent = 0; # Supress indentation and new-lines
$Data::Dumper::Terse = 1; # Output values only, supress variable names if possible

=head1 NAME

C<NCM::Component::spma::apt> - NCM SPMA backend for apt

=head1 SYNOPSIS

This document describes how to control the behaviour of the package manager itself.
For information on how to manage packages with Quattor, please check
L<http://quattor.org/documentation/2013/04/05/package-management.html>.

=head1 DESCRIPTION

This plugin implements an apt backend for C<ncm-spma>, the approach taken is to defer as much work as possible to apt.

A single SPMA run consists of the following steps:

=over

=item Setup source directory if required

=item Remove sources that are not found in the profile

=item Update source cache from upstream sources

=item Upgrade already installed packages

=item Install packages specified in the profile that are not installed

=item Mark any packages installed but not in the profile as automatically installed

=item Ask apt to remove all automatically installed packages that are not satisfying dependencies of other packages

=back

=head1 RESOURCES

Only a very minimal schema is implemented.

Sources listed under C</software/repositories> will be configured,
URLs should be followed by the suite and sections required e.g. C<http://example.org/debian unstable main>

Packages listed under C</software/packages> will be installed, version and architecture locking (including multiarch) is fully implemented.

=cut

use parent qw(NCM::Component CAF::Path);
use CAF::Path 21.12.1;
use CAF::Process;
use CAF::FileWriter;
use CAF::FileEditor;
use EDG::WP4::CCM::Path qw(escape unescape);
use EDG::WP4::CCM::TextRender;
use NCM::Component::spma::yum;
use CAF::Object qw(SUCCESS);
use Set::Scalar;
use Readonly;

Readonly my $DIR_SOURCES => "/etc/apt/sources.list.d";
Readonly my $DIR_PREFERENCES => "/etc/apt/preferences.d";
Readonly my $TEMPLATE_SOURCES => "apt/source.tt";
Readonly my $TEMPLATE_PREFERENCES => "apt/preferences.tt";
Readonly my $TEMPLATE_CONFIG => "apt/config.tt";
Readonly my $FILE_CONFIG => "/etc/apt/apt.conf.d/98quattor.conf";
Readonly my $TREE_SOURCES => "/software/repositories";
Readonly my $TREE_PKGS => "/software/packages";
Readonly my $BIN_APT_GET => "/usr/bin/apt-get";
Readonly my $BIN_APT_MARK => "/usr/bin/apt-mark";
Readonly my $BIN_APT_CACHE => "/usr/bin/apt-cache";
Readonly my $BIN_DPKG_QUERY => "/usr/bin/dpkg-query";
Readonly my $CMD_APT_UPDATE => [$BIN_APT_GET, qw(-qq update)];
Readonly my $CMD_APT_UPGRADE => [$BIN_APT_GET, qw(-qq dist-upgrade)];
Readonly my $CMD_APT_INSTALL => [$BIN_APT_GET, qw(-qq install)];
Readonly my $CMD_APT_AUTOREMOVE => [$BIN_APT_GET, qw(-qq autoremove)];
Readonly my $CMD_APT_MARK => [$BIN_APT_MARK, qw(-qq)];
Readonly my $CMD_APT_AVAILABLE => [$BIN_APT_CACHE, qw(pkgnames)];
Readonly my $CMD_DPKG_QUERY => [$BIN_DPKG_QUERY, qw(-W -f=${db:Status-Abbrev};${Package}\n)];

our $NoActionSupported = 1;

# Wrapper function for calling apt commands
sub _call_apt
{
    my ($self, $cmd, $ok) = @_;
    $self->debug(5, '_call_apt: Called with args ', Dumper($cmd));

    my $proc = CAF::Process->new($cmd);
    my $output = $proc->output();
    my $exitstatus = $? >> 8; # Get exit status from highest 8-bits
    $self->debug(5, "_call_apt: $proc exited with $exitstatus");
    if ($exitstatus > 0) {
        $output =~ tr{\n}{ };
        my $method = $ok ? 'warn' : 'error';
        $self->$method("_call_apt: $proc failed with \"$output\"");
    }
    return $ok || $exitstatus == 0;
}

# If user specified sources (userrepos) are not allowed, removes any
# sources present in the system that are not listed in $allowed_sources.
sub cleanup_old_sources
{
    my ($self, $sources_dir, $allowed_sources) = @_;
    $self->debug(5, "cleanup_old_sources: Called with args ", $sources_dir, $allowed_sources);

    if ($self->directory_exists($sources_dir)) {
        my $current = Set::Scalar->new(@{$self->listdir($sources_dir, filter => qr{\.list$}, adddir => 1)});
        my $allowed = Set::Scalar->new(map("$sources_dir/" . $_->{name} . ".list", @$allowed_sources));
        my $to_remove = $current - $allowed;
        foreach my $source (@$to_remove) {
            $self->verbose("Unlinking outdated source $source");
            if (!defined ($self->cleanup($source, ""))) {
                $self->error("Cannot cleanup source $source: $self->{fail}.");
                return 0;
            }
        }
    } else {
        $self->error("Cannot cleanup sources, $sources_dir doesn't exist.");
        return 0;
    }
    return 1;
}


# Creates the sources directory if needed.
sub initialize_sources_dir
{
    my ($self, $sources_dir) = @_;
    $self->debug(5, "initialize_sources_dir: Called with args($sources_dir)");

    if (! $self->directory($sources_dir)) {
        $self->error("Unable to create source dir $sources_dir: $self->{fail}");
        return 0;
    }
    return 1;
}

# Generates the source files in $sources_dir based on the contents
# of the $sources subtree. It uses Template::Toolkit $template to render
# the file.
# Returns undef on errors, or the number of source files that were changed.
sub generate_sources
{
    my ($self, $sources_dir, $sources, $template) = @_;
    $self->debug(5, "generate_sources: Called with args($sources_dir, $sources, $template)");

    my $changes = 0;

    foreach my $source (@$sources) {
        $self->debug(5, "Generating source: $source->{name}");
        my $prots = $source->{protocols}->[0];
        my $rs = EDG::WP4::CCM::TextRender->new($template, $source, relpath => 'spma') ;
        if ($rs) {
            my $fh = $rs->filewriter("$sources_dir/$source->{name}.list") ;
            $changes += $fh->close() || 0; # handle undef
        } else {
            $self->error("Invalid template '$template' passed to generate_sources");
            return;
        }
    }

    return $changes;
}

# Write apt configuration file
sub configure_apt
{
    my ($self, $config) = @_;
    $self->debug(5, 'configure_apt: Called with args', Dumper($config));

    my $tr = EDG::WP4::CCM::TextRender->new($TEMPLATE_CONFIG, $config, relpath => 'spma');
    if ($tr) {
        my $fh = $tr->filewriter($FILE_CONFIG);
        return $fh->close() || 0; # handle undef
    }
    $self->error('configure_apt: TextRender failed to render configuration');
    return;
}

# Returns a set of all installed packages
sub get_installed_pkgs
{
    my ($self) = @_;
    $self->debug(5, 'get_installed_pkgs: Called');

    my $out = CAF::Process->new($CMD_DPKG_QUERY, keeps_state => 1) ->output();
    my $exitstatus = $? >> 8; # Get exit status from highest 8-bits
    if ($exitstatus) {
        $self->debug(5, "dpkg command returned $exitstatus");
        return 0;
    }
    # db:Status-Abbrev is three characters, we are looking for
    #   desired action  i (but anything is fine here)
    #   package status  i (indicating currently installed)
    #   error flag      a single space (indicating no error condition)
    my @pkgs = map { substr $_, 4 } grep {m/^.i /} split("\n", $out);

    return Set::Scalar->new(@pkgs);
}

# Returns a set of all available package names
sub get_available_pkgs
{
    my ($self) = @_;
    $self->debug(5, 'get_available_pkgs: Called');

    my $out = CAF::Process->new($CMD_APT_AVAILABLE, keeps_state => 1) ->output();
    my $exitstatus = $? >> 8; # Get exit status from highest 8-bits
    if ($exitstatus) {
        $self->debug(5, "dpkg command returned $exitstatus");
        return 0;
    }
    my @pkgs = split("\n", $out);

    return Set::Scalar->new(@pkgs);
}

# For a given package name, extract version and architecture from tree passed in details
# returns an arrayref of packages formatted with name, version and architecture for use with apt
sub get_package_version_arch
{
    my ($self, $name, $details) = @_;
    $self->debug(5, "get_package_version_arch: Called with args($name, ", Dumper($details), ")");

    my @versions;

    if (defined($details) and %$details) {
        foreach my $version (sort keys %$details) {
            my $params = $details->{$version};
            $version = unescape($version);
            if ($params->{arch}) {
                foreach my $arch (sort keys %{ $params->{arch} }) {
                    $self->debug(4, 'get_package_version_arch: Adding package ', $name, ' with version ', $version, ' and architecture ', $arch, ' to list');
                    push(@versions, sprintf('%s:%s=%s', $name, $arch, $version));
                }
            } else {
                $self->debug(4, 'get_package_version_arch: Adding package ', $name, ' with version ', $version, ' but without architecture to list');
                push(@versions, sprintf('%s=%s', $name, $version));
            }
        }
    } else {
        $self->debug(4, 'get_package_version_arch: Adding package ', $name, ' without version or architecture to list');
        push(@versions, $name);
    }

    $self->debug(5, 'get_package_version_arch: returning arrayref:', Dumper(\@versions));

    return \@versions;
}

# For a bare list of packages, apply versions from the configuration tree
# Returns an arrayref of packages with versions attached
sub apply_package_version_arch
{
    my ($self, $packagelist, $packagetree) = @_;

    $self->debug(5, "apply_package_version_arch: Called with args", $packagelist, Dumper($packagetree));

    my @results;
    my @notfound;

    foreach my $name (@$packagelist) {
        my $name_escaped = escape($name);
        if (exists($packagetree->{$name_escaped})) {
            my $versions = $self->get_package_version_arch($name, $packagetree->{$name_escaped});
            push(@results, @$versions);
        } else {
            push(@notfound, $name);
        }
    }
    $self->error("Could not find packages: ", join(", ", @notfound)) if @notfound;

    return \@results;
}


# Return a set of desired packages.
sub get_desired_pkgs
{
    my ($self, $pkgs) = @_;
    $self->debug(5, "get_desired_pkgs: Called with args", Dumper($pkgs));

    my $packages = Set::Scalar->new();

    foreach my $name_escaped (sort keys %$pkgs) {
        my $name = unescape($name_escaped);
        if (!$name) {
            $self->error("Invalid package name: ", $name);
            return;
        }
        $packages->insert($name);
    }
    return $packages;
}


# Update package metadata from upstream sourcesitories
sub resynchronize_package_index
{
    my ($self) = @_;
    $self->debug(5, 'resynchronize_package_index: Called');

    return $self->_call_apt($CMD_APT_UPDATE);
}


# Upgrade existing packages
sub upgrade_packages
{
    my ($self) = @_;
    $self->debug(5, 'upgrade_packages: Called');

    # it's ok if this produces errors (eg unfinished stuff)
    # TODO: add support for 'apt --fix-broken install' and things like that
    return $self->_call_apt($CMD_APT_UPGRADE, 1);
}


# Install packages
sub install_packages
{
    my ($self, $packages) = @_;
    $self->debug(5, 'install_packages: Called with args', Dumper($packages));

    return $self->_call_apt([@$CMD_APT_INSTALL, @$packages]);
}


# Mark packages as automatically installed
# this signals to apt that they are no longer required and may be cleaned up by autoremove
sub mark_packages_auto
{
    my ($self, $packages) = @_;
    $self->debug(5, "mark_packages_auto: Called with args", Dumper($packages));

    return $self->_call_apt([@$CMD_APT_MARK, 'auto', @$packages]);
}


# Remove automatically installed packages
sub autoremove_packages
{
    my ($self) = @_;
    $self->debug(5, 'autoremove_packages: Called');

    return $self->_call_apt([@$CMD_APT_AUTOREMOVE]);
}


sub Configure
{
    my ($self, $config) = @_;

    # Get configuration trees
    my $tree_sources = $config->getTree($TREE_SOURCES);
    $self->debug(5, 'TREE_SOURCES ', $TREE_SOURCES, Dumper $tree_sources);
    my $tree_pkgs = $config->getTree($TREE_PKGS);
    $self->debug(5, 'TREE_PKGS ', $TREE_PKGS, Dumper $tree_pkgs);
    my $tree_component = $config->getTree($self->prefix());
    $self->debug(5, 'tree_component ', $self->prefix, Dumper $tree_component);

    defined($self->configure_apt($tree_component)) or return 0;

    defined($self->initialize_sources_dir($DIR_SOURCES)) or return 0;

    # Remove unknown sources if allow_user_sources is not set
    if (! $tree_component->{usersources}) {
        $self->info('Removing unknown source lists');
        $self->cleanup_old_sources($DIR_SOURCES, $tree_sources) or return 0;
    };

    $self->info('Generating ', scalar(@$tree_sources), ' source lists');
    defined($self->generate_sources(
        $DIR_SOURCES,
        $tree_sources,
        $TEMPLATE_SOURCES,
    )) or return 0;

    $self->info('Synchronizing package index');
    $self->resynchronize_package_index() or return 0;

    $self->info('Applying upgrades to installed packages');
    $self->upgrade_packages() or return 0;

    my $packages_installed = $self->get_installed_pkgs() or return 0;
    my $packages_available = $self->get_available_pkgs() or return 0;
    my $packages_desired = $self->get_desired_pkgs($tree_pkgs) or return 0;

    my $packages_unwanted = $packages_installed->difference($packages_desired);
    my $packages_to_install = $packages_desired->difference($packages_installed);
    my $packages_unavailable = $packages_desired->difference($packages_available);

    if ($packages_unavailable->size > 0) {
        $self->warn('The following packages are unavailable, they may have been renamed or virtual: ', $packages_unavailable);
    }

    $self->debug(4, 'Installed packages: ', $packages_installed);
    $self->debug(4, 'Desired packages: ', $packages_desired);
    $self->debug(4, 'Unavailable packages: ', $packages_unavailable);
    $self->debug(4, 'Packages installed but unwanted: ', $packages_unwanted);
    $self->debug(4, 'Packages to install (desired but not installed): ', $packages_to_install);

    my $apt_packages_to_install = $self->apply_package_version_arch($packages_to_install, $tree_pkgs);
    $self->info('Installing ', $packages_to_install->size,' missing packages');
    $self->install_packages($apt_packages_to_install) or return 0;

    # If user installed packages are not permitted, mark all unlisted packages as automatically installed and
    # ask apt to remove any of these that are not required to satisfy dependencies of the desired package list
    if (! $tree_component->{userpkgs}) {
        $self->info('Marking ', $packages_unwanted->size, ' packages as unwanted and removing any that are not dependencies of installed packages');
        $self->mark_packages_auto($packages_unwanted) or return 0;
        $self->autoremove_packages() or return 0;
    }

    return 1;
}


1; # required for Perl modules
