#${PMpre} NCM::Component::spma::apt${PMpost}

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
use CAF::Path 17.3.1;
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
Readonly my $BIN_DPKG_QUERY => "/usr/bin/dpkg-query";
Readonly my $CMD_APT_UPDATE => [$BIN_APT_GET, qw(-qq update)];
Readonly my $CMD_APT_UPGRADE => [$BIN_APT_GET, qw(-qq dist-upgrade)];
Readonly my $CMD_APT_INSTALL => [$BIN_APT_GET, qw(-qq install)];
Readonly my $CMD_APT_AUTOREMOVE => [$BIN_APT_GET, qw(-qq autoremove)];
Readonly my $CMD_APT_MARK => [$BIN_APT_MARK, qw(-qq)];
Readonly my $CMD_DPKG_QUERY => [$BIN_DPKG_QUERY, qw(-W -f=${db:Status-Abbrev};${Package}\n)];

our $NoActionSupported = 1;


# If user specified sources (userrepos) are not allowed, removes any
# sources present in the system that are not listed in $allowed_sources.
sub cleanup_old_sources
{
    my ($self, $sources_dir, $allowed_sources) = @_;
    $self->debug(5, 'Entered cleanup_old_sources()');

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
    $self->debug(5, 'Entered initialize_sources_dir()');

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
    $self->debug(5, 'Entered generate_sources()');

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
            return 0;
        }
    }

    return $changes;
}

# Write apt configuration file
sub configure_apt
{
    my ($self, $config) = @_;
    $self->debug(5, 'Entered configure_apt()');

    my $tr = EDG::WP4::CCM::TextRender->new($TEMPLATE_CONFIG, $config, relpath => 'spma');
    if ($tr) {
        my $fh = $tr->filewriter($FILE_CONFIG);
        return $fh->close() || 0; # handle undef
    } else {
        return 0;
    }
}

# Returns a set of all installed packages
sub get_installed_pkgs
{
    my $self = shift;
    $self->debug(5, 'Entered get_installed_pkgs()');

    my $out = CAF::Process->new($CMD_DPKG_QUERY, keeps_state => 1) ->output();
    if ($?) {
        $self->debug(5, "dpkg command returned $?");
        return 0;
    }
    # db:Status-Abbrev is three characters, we are looking for
    #   desired action  i (but anything is fine here)
    #   package status  i (indicating currently installed)
    #   error flag      a single space (indicating no error condition)
    my @pkgs = map { substr $_, 4 } grep {m/^.i /} split("\n", $out);

    return Set::Scalar->new(@pkgs);
}

# For a given package name, extract version and architecture from tree passed in details
# returns an arrayref of packages formatted with name, version and architecture for use with apt
sub get_package_version_arch
{
    my ($self, $name, $details) = @_;
    $self->debug(5, 'Entered get_package_version_arch()');

    my @versions;

    if ($details) {
        foreach my $version (sort keys %$details) {
            my $params = $details->{$version};
            $version = unescape($version);
            if ($params->{arch}) {
                foreach my $arch (sort keys %{ $params->{arch} }) {
                    $self->debug(5, '  Adding package ', $name, ' with version ', $version, ' and architecture ', $arch, ' to list');
                    push(@versions, sprintf('%s:%s=%s', $name, $arch, $version));
                }
            } else {
                $self->debug(5, '  Adding package ', $name, ' with version ', $version, ' but without architecture to list');
                push(@versions, sprintf('%s=%s', $name, $version));
            }
        }
    } else {
        $self->debug(5, '  Adding package ', $name, ' without version or architecture to list');
        push(@versions, $name);
    }

    return \@versions;
}

# For a bare list of packages, apply versions from the configuration tree
# Returns an arrayref of packages with versions attached
sub apply_package_version_arch
{
    my ($self, $packagelist, $packagetree) = @_;

    $self->debug(5, 'Entered apply_package_version_arch()');

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
    $self->debug(5, 'Entered get_desired_pkgs()');

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
    my $self = shift;
    $self->debug(5, 'Entered resynchronize_package_index()');

    my $cmd = CAF::Process->new($CMD_APT_UPDATE, keeps_state => 1);
    return $cmd->execute() ? 1 : undef;
}


# Upgrade existing packages
sub upgrade_packages
{
    my ($self) = @_;
    $self->debug(5, 'Entered upgrade_packages()');

    my $cmd = CAF::Process->new($CMD_APT_UPGRADE) ;
    return $cmd->execute() ? 1 : undef;
}


# Install packages
sub install_packages
{
    my ($self, $packages) = @_;
    $self->debug(5, 'Entered install_packages()');

    my $cmd = CAF::Process->new([@$CMD_APT_INSTALL, @$packages]) ;
    return $cmd->execute() ? 1 : undef;
}


# Mark packages as automatically installed
# this signals to apt that they are no longer required and may be cleaned up by autoremove
sub mark_packages_auto
{
    my ($self, $packages) = @_;
    $self->debug(5, 'Entered mark_packages_auto()');

    my $cmd = CAF::Process->new([@$CMD_APT_MARK, 'auto', @$packages]) ;
    return $cmd->execute() ? 1 : undef;
}


# Remove automatically installed packages
sub autoremove_packages
{
    my ($self) = @_;
    $self->debug(5, 'Entered autoremove_packages()');

    my $cmd = CAF::Process->new([@$CMD_APT_AUTOREMOVE]) ;
    return $cmd->execute() ? 1 : undef;
}


sub Configure
{
    my ($self, $config) = @_;
    $self->debug(5, 'Entered Configure()');

    # Get configuration trees
    my $tree_sources = $config->getTree($TREE_SOURCES);
    my $tree_pkgs = $config->getTree($TREE_PKGS);
    my $tree_component = $config->getTree($self->prefix());

    $self->configure_apt($tree_component) or return 0;

    $self->initialize_sources_dir($DIR_SOURCES) or return 0;

    # Remove unknown sources if allow_user_sources is not set
    if (! $tree_component->{usersources}) {
        $self->cleanup_old_sources($DIR_SOURCES, $tree_sources) or return 0;
    };

    $self->generate_sources(
        $DIR_SOURCES,
        $tree_sources,
        $TEMPLATE_SOURCES,
    ) or return 0;

    $self->resynchronize_package_index() or return 0;

    $self->upgrade_packages() or return 0;

    my $packages_installed = $self->get_installed_pkgs() or return 0;
    my $packages_desired = $self->get_desired_pkgs($tree_pkgs) or return 0;
    my $packages_unwanted = $packages_installed->difference($packages_desired);

    $self->debug(5, 'Installed packages:', $packages_installed);
    $self->debug(5, 'Desired packages:', $packages_desired);
    $self->debug(5, 'Packages installed but unwanted:', $packages_unwanted);

    my $packages_to_install = $self->apply_package_version_arch($packages_desired, $tree_pkgs) or return 0;

    $self->debug(5, 'Packages to install ', $packages_to_install);

    $self->install_packages($packages_to_install) or return 0;

    # If user installed packages are not permitted, mark all unlisted packages as automatically installed and
    # ask apt to remove any of these that are not required to satisfy dependencies of the desired package list
    if (! $tree_component->{userpkgs}) {
        $self->mark_packages_auto($packages_unwanted) or return 0;
        $self->autoremove_packages() or return 0;
    }

    return 1;
}


1; # required for Perl modules
