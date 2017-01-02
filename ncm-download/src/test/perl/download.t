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
use CAF::FileWriter;
use Test::MockModule;
use Cwd;
use Readonly;
use Test::Quattor::Filetools qw(writefile);

Readonly my $SRC => "target/test/source";
Readonly my $FILE => "target/test/file";

my $cmp = NCM::Component::download->new("download");
my $cfg = get_config_for_profile('download');

my $mock = Test::MockModule->new("NCM::Component::download");

writefile($SRC, "src1");

my $tmpfile = $cmp->_tempfile($FILE);
is ($tmpfile, 'target/test/.file.part', "temporary file named as expected");

=item The remote file is too recent or in the future.

Nothing is done

=cut

my %opts = (
    href => sprintf("file://%s/$SRC", getcwd()),
    timeout => 1,
    min_age => 60, # 1 hour
    );

my (%file_moves, %file_cleanups);
$mock->mock('move', sub { $file_moves{$_[1]}->{$_[2]}++; return 1; });
$mock->mock('cleanup', sub { $file_cleanups{$_[1]}++; return 1; });
command_history_reset();
is($cmp->retrieve($FILE, %opts), 1, "Invocation with a too recent file succeeds");
ok(command_history_ok(undef, ['curl']), "curl is not called if the remote file is too recent");

=item The remote file may be downloaded

=cut

$opts{min_age} = 0;

is($cmp->retrieve($FILE, %opts), 1, "Basic retrieve invocation succeeds");

my $cmd = get_command("/usr/bin/curl -s -R -f --create-dirs -o $tmpfile -m $opts{timeout} $opts{href}");

ok($cmd, "Curl command called as expected");
is($file_moves{$tmpfile}->{$FILE}, 1, "temporary file moved to real file");
is($file_cleanups{$tmpfile}, 1, "temporary file cleaned up");

=item allow_older

=cut

# make the destination, content not relevant
# measurable timedifference between source and current file
sleep 2;
writefile($FILE, "file");
diag "allow_older time $SRC ", (stat($SRC))[9], " $FILE ", (stat($FILE))[9];

# also fake the file for mocked CAF::Path -> file_exists
my $fh = CAF::FileWriter->new($FILE);
print $fh "file";
$fh->close();

ok($cmp->file_exists($FILE), "current file $FILE exists (CAF::Path test)");
ok(-f $FILE, "current file $FILE exists (-f test)");

command_history_reset();
is($cmp->retrieve($FILE, %opts), 1, "Invocation with a more recent current file succeeds");
ok(command_history_ok(undef, ['curl']), "curl is not called if the current file is more recent");

command_history_reset();
is($cmp->retrieve($FILE, allow_older =>1, %opts), 1, "Invocation with a more recent current file and allow_older succeeds");
ok(command_history_ok(['curl']), "curl is called if the current file is more recent and allow_older is set");

=back

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
set_command_status('/usr/bin/curl -s -R -f --create-dirs -o /a/b/.c1.part https://broken/something1', 1);

command_history_reset();
ok($cmp->Configure($cfg), "configure ok");

ok(command_history_ok([
    # try proxy, broken fails, then, working
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/.c1.part https://broken/something1',
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/.c1.part https://working/something1',
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/.c2.part https://working/something2',
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/.c3.part https://working/something3',
    # start with trying working proxy
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/.d.part abc://working/something/else',
    # no proxy, with postprocess
    '/usr/bin/curl -s -R -f --create-dirs -o /a/b/.e.part def://ok/something/entirely/different',
    'postprocess /a/b/e',
], [
    # working2 proxy should not be used
    'https://working2/',
]), "curl called as expected");

is(scalar(grep {m/curl.*?broken/} @Test::Quattor::command_history),
   1, 'broken proxy only tried once');


done_testing();
