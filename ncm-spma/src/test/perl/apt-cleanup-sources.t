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
use Test::MockModule;
use NCM::Component::spma::apt;
use CAF::Path;
use CAF::FileWriter;
use Set::Scalar;


Readonly my $SOURCE_DIR => "target/test/clean.sources.list.d";

my $sources = [{
    name => "source1",
    owner => 'localuser@localdomain',
    protocols => [{
        name => "http",
        url => "http://localhost.localdomain",
    }],
}];

my $cmp = NCM::Component::spma::apt->new("spma");
my $mock = Test::MockModule->new('NCM::Component::spma::apt');

my $immutable;
my $directory_exists;
my $sourcefiles;


$mock->mock('_glob', sub {
    return @$sourcefiles;
});


$mock->mock('cleanup', sub {
    shift;
    if (!$immutable) {
        my $filename = shift;
        $sourcefiles->delete($filename) || return undef;
        return 1;
    };
    return undef;
});


$mock->mock('directory_exists', sub {
    return $directory_exists;
});


=pod

=head2 The source directory doesn't exist

If the source directory doesn't exist, the error should be
reported.

=cut

$immutable = 0;
$directory_exists = 0;
$sourcefiles = Set::Scalar->new();

is($cmp->cleanup_old_sources($SOURCE_DIR), 0, "Throw error if source dir does not-exist source dir");
is($cmp->{ERROR}, 1, "Report Non-existing source dir to the user");

=pod

=head2 The source exists and contains files that should be removed

In this case, any unwanted files should be removed

=cut

$immutable = 0;
$directory_exists = 1;
$sourcefiles = Set::Scalar->new(map { "$SOURCE_DIR/$_.list" } qw(source1 source2));

ok($cmp->cleanup_old_sources($SOURCE_DIR, $sources), "Cleanup old source files");
ok($sourcefiles->contains("$SOURCE_DIR/source1.list"), "Preserve allowed source file");
ok(!$sourcefiles->contains("$SOURCE_DIR/source2.list"), "Remove unwanted source file");

=pod

=head2 The source exists but the unwanted files cannot be removed

In this case, the error must be reported

=cut

$immutable = 1;
$directory_exists = 1;
$sourcefiles = Set::Scalar->new(map { "$SOURCE_DIR/$_.list" } qw(source1 source2));

ok(!$cmp->cleanup_old_sources($SOURCE_DIR, $sources), "Report error when an outdated repo cannot be removed");

done_testing();
