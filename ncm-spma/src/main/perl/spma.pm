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
use parent 'NCM::Component';
our $EC=LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element qw(unescape);

use CAF::Process;
use CAF::FileWriter;
use LC::Exception qw(SUCCESS);
use Set::Scalar;
use File::Path qw(mkpath);
use Readonly;

Readonly my $REPOS_DIR => "/etc/yum.repos.d";

our $NoActionSupported = 1;

# Removes any repositories present in the system that are not listed in
# $allowed_repos.
sub cleanup_old_repos
{
    my ($self, $repo_dir, $allowed_repos) = @_;

    warn "Repos dir is $repo_dir";
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
	if (!mkpath($repo_dir)) {
	    self->error("Unable to create repository dir $repo_dir");
	    return 0;
	}
    }
    return 1;
}

sub generate_repos
{
    my ($self, $repos) = @_;


    return 1;
}

sub Configure
{
    my ($self, $config) = @_;

    $self->initialize_repos_dir($REPOS_DIR)) || return 0;
    return 1;
}
1; # required for Perl modules
