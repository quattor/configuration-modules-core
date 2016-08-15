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
use Test::Quattor qw(download);
use NCM::Component::download;
use Test::MockModule;
use CAF::FileWriter;
use Cwd;
use Readonly;

Readonly my $FILE => "target/test/file";

my $cmp = NCM::Component::download->new("download");
my $cfg = get_config_for_profile('download');

my $mock = Test::MockModule->new("NCM::Component::download");

my $fh = CAF::FileWriter->new("target/test/source");
print $fh "Hello\n";
$fh->close();

=pod

=item The remote file is too recent or in the future.

Nothing is done

=cut

my %opts = (href => sprintf("file://%s/target/test/source", getcwd()),
            timeout => 1,
            min_age => 60);

is($cmp->retrieve($FILE, %opts), 1, "Invocation with a too recent file succeeds");

my $cmd = get_command("/usr/bin/curl -s -R -f --create-dirs -o $FILE -m $opts{timeout} $opts{href}");

ok(!$cmd, "curl is not called if the remote file is too recent");

=pod

=item The remote file may be downloaded

=back

=cut

$opts{min_age} = 0;

is($cmp->retrieve($FILE, %opts), 1, "Basic retrieve invocation succeeds");

$cmd = get_command("/usr/bin/curl -s -R -f --create-dirs -o $FILE -m $opts{timeout} $opts{href}");

ok($cmd, "Curl command called as expected");

=pod

=head2 Failure situations

=over

=item The remote file doesn't exist

=cut

$opts{href} .= "kljhljhlujh8hp9";

is($cmp->retrieve($FILE, %opts), 0, "Retrieve of non-existing files fails");

=head2 Configure

=cut

# Always new, but not too new (min_age of 2 min)
$mock->mock('get_remote_timestamp', sub { return time() - 120; } );

# broken proxy fails
set_command_status('/usr/bin/curl -s -R -f --create-dirs -o /a/b/c https://broken/something', 1);

command_history_reset();
ok($cmp->Configure($cfg), "configure ok");

ok(command_history_ok([
    # try proxy, broken fails, then, working
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/c https://broken/something',
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/c https://working/something',
    # start with trying working proxy
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/d abc://working/something/else',
    # no proxy, with postprocess
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/e def://ok/something/entirely/different',
    'postprocess /a/b/e',
]), "curl called as expected");

# Requires build-tools 1.50
#is(scalar(grep {m/curl.*?broken/} @Test::Quattor::command_history),
#   1, 'broken proxy only tried once');


done_testing();
