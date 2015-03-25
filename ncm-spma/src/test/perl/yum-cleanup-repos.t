# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the cleanup_old_repos method.  This method ensures that
outdated repositories in /etc/yum.repos.d are removed.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use English;

use Test::Quattor;
use Test::More;
use NCM::Component::spma::yum;

use File::Path qw(mkpath rmtree);
use LC::File;

Readonly my $REPO_DIR => "target/test/clean.repos.d";

sub initialize_repos
{
    mkpath($REPO_DIR);
    open(FH, ">", "$REPO_DIR/repository.repo");
    open(FH, ">", "$REPO_DIR/repository2.repo");
}

my $repos = [ { name => "repository",
		owner => 'localuser@localdomain',
		protocols => [ { name => "http",
				 url => "http://localhost.localdomain" }
			     ]
	      }
	    ];

my $cmp = NCM::Component::spma::yum->new("spma");

=pod

=head2 The repository directory doesn't exist

If the repository directory doesn't exist, the error should be
reported.

=cut

rmtree($REPO_DIR);

is($cmp->cleanup_old_repos($REPO_DIR), 0, "Non-existing repository dir causes an error");
is($cmp->{ERROR}, 1, "Non-existing repository dir is reported to the user");

=pod

=head2 The repository exists and contains files that should be removed

In this case, any unwanted files should be removed

=cut

initialize_repos();

is($cmp->cleanup_old_repos($REPO_DIR, $repos), 1, "Removal of files succeeds");
ok(!-e "$REPO_DIR/repository2.repo", "Unwanted repo scheduled for removal");
ok(-e "$REPO_DIR/repository.repo", "Wanted file not marked for deletion");

=pod

=head2 The repository exists but the unwanted files cannot be removed

In this case, the error must be reported

=cut

initialize_repos();
if ($EUID) {
  chmod(0500, $REPO_DIR);
} else {
  diag("Trying to set immutable bit for root user to create unremovable files. ".
       "Run 'chattr -i $REPO_DIR/*repo' to cleanup in case of failure during this test.");

  system("chattr +i $REPO_DIR/*repo");
}
is($cmp->cleanup_old_repos($REPO_DIR, $repos), 0,
   "Error reported when an outdated repo cannot be removed");
is($cmp->{ERROR}, 2, "Error in unlink is reported");

# Restore permissions on the repository for future executions.
if ($EUID) {
  chmod(0700, $REPO_DIR);
} else {
  system("chattr -i $REPO_DIR/*repo");
}

=pod

=head2 The userpkgs flag is set

In this case, nothing should be done.

=cut

initialize_repos();
is($cmp->cleanup_old_repos($REPO_DIR, $repos, 1), 1, "userpkgs succeeds");
ok(-e "$REPO_DIR/repository2.repo", "Unlisted repo is kept under userpkgs");

done_testing();
