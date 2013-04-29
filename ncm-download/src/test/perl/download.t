# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Simple tests for the download method

Basic tests for the download commponent.

=head1 TESTS

=head2 Successful executions

The remote file exists and can be downloaded.

=over

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::download;
use Test::MockModule;
use CAF::FileWriter;
use Cwd;
use Readonly;

Readonly my $FILE => "target/test/file";

my $cmp = NCM::Component::download->new("download");

my $mock = Test::MockModule->new("NCM::Component::download");

my $fh = CAF::FileWriter->new("target/test/source");
print $fh "Hello\n";
$fh->close();

=pod

=item The remote file is too recent or in the future.

Nothing is done

=cut

my %opts = (file => $FILE,
	    href => sprintf("file://%s/target/test/source", getcwd()),
	    timeout => 1,
	    min_age => 60);

is($cmp->download(%opts), 1, "Invocation with a too recent file succeeds");

my $cmd = get_command("/usr/bin/curl -s -R -f --create-dirs -o $opts{file} -m $opts{timeout} $opts{href}");

ok(!$cmd, "curl is not called if the remote file is too recent");

=pod

=item The remote file may be downloaded

=back

=cut

$opts{min_age} = 0;

is($cmp->download(%opts), 1, "Basic invocation succeeds");

$cmd = get_command("/usr/bin/curl -s -R -f --create-dirs -o $opts{file} -m $opts{timeout} $opts{href}");

ok($cmd, "Curl command called as expected");

=pod

=head2 Failure situations

=over

=item The remote file doesn't exist

=cut

$opts{href} .= "kljhljhlujh8hp9";

is($cmp->download(%opts), 0, "Download of non-existing files fails");

done_testing();
