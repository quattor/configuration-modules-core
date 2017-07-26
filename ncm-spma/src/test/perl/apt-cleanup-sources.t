# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the cleanup_old_sources method.  This method ensures that
outdated sources in /etc/apt/sources.list.d/ are removed.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use English;

use Test::Quattor;
use Test::More;
use NCM::Component::spma::apt;


Readonly my $SOURCE_DIR => "/test/clean.sources.list.d";

my $sources = [{
    name => "source1",
    owner => 'localuser@localdomain',
    protocols => [{
        name => "http",
        url => "http://localhost.localdomain",
    }],
}];

my $cmp = NCM::Component::spma::apt->new("spma");

=pod

=head2 The source directory doesn't exist

If the source directory doesn't exist, the error should be
reported.

=cut

ok(!$cmp->directory_exists($SOURCE_DIR), "Test source dir does not exist");
is($cmp->cleanup_old_sources($SOURCE_DIR), 0, "Return false if source dir does not exist");
is($cmp->{ERROR}, 1, "Report error non-existing source dir to the user");

=pod

=head2 The source exists and contains files that should be removed

In this case, any unwanted files should be removed

=cut

# this creates the $SOURCE_DIR
set_file_contents("$SOURCE_DIR/source1.list", "source1");
set_file_contents("$SOURCE_DIR/source2.list", "source2");
set_file_contents("$SOURCE_DIR/source2.garbage", "source2 garbage");

ok($cmp->cleanup_old_sources($SOURCE_DIR, $sources), "Cleanup old source files");
ok($cmp->file_exists("$SOURCE_DIR/source1.list"), "Preserve allowed source file");
ok(!$cmp->file_exists("$SOURCE_DIR/source2.list"), "Remove unwanted source file");
ok($cmp->file_exists("$SOURCE_DIR/source2.garbage"), "Non-list files untouched");

=pod

=head2 The source exists but the unwanted files cannot be removed

In this case, the error must be reported

=cut

set_file_contents("$SOURCE_DIR/source3.list", "source3");
set_immutable("$SOURCE_DIR/source3.list");
ok(!$cmp->cleanup_old_sources($SOURCE_DIR, $sources), "Return false when an outdated repo cannot be removed");
is($cmp->{ERROR}, 2, "Report error when an outdated repo cannot be removed");
ok($cmp->file_exists("$SOURCE_DIR/source3.list"), "Immutable file not removed");

done_testing();
