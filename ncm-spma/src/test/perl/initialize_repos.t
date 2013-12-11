# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the the initialize_repos_d method.  This method creates
/etc/yum.repos.d if it doesn't exist.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;


use Test::Quattor;
use Test::More;
use NCM::Component::spma::yum;

use File::Path qw(mkpath rmtree);
use LC::File;

Readonly my $VALID_DIR => "target/test/init.repos.d";
Readonly my $INVALID_DIR => "/dev/null/foo";

my $cmp = NCM::Component::spma::yum->new("spma");

rmtree($VALID_DIR);

is($cmp->initialize_repos_dir($VALID_DIR), 1,
   "Repository directory correctly created");
ok(-d $VALID_DIR, "Repository directory actually created");
is($cmp->{VERBOSE}, 1, "Directory creation reported");
is($cmp->initialize_repos_dir($VALID_DIR), 1,
   "Repository creation is idempotent");
is($cmp->{VERBOSE}, 1, "No directory operations in the second call");

is($cmp->initialize_repos_dir($INVALID_DIR), 0,
   "Invalid repository couldn't be created");
ok(!-d $INVALID_DIR, "The repository doesn't really exist");
is($cmp->{ERROR}, 1, "Error in repository creation is reported");

done_testing();
