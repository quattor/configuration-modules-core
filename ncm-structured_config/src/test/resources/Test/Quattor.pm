# -*- mode: cperl -*-

=pod

=head1 SYNOPSIS

    use Test::Quattor qw(test_profile1 test_profile2...);

=head1 DESCRIPTION

C<Test::Quattor>

Module preparing the environment for testing Quattor code.

=head1 LOADING

When loading this module it will compile any profiles given as arguments. So,

    use Test::Quattor qw(foo);

will trigger a compilation of C<src/test/resources/foo.pan> and the
creation of a binary cache for it. The compiled profile will be stored
as C<target/test/profiles/foo.json>, while the cache will be stored in
under C<target/test/profiles/foo/>.

This binary cache may be converted in an
L<EDG::WP4::CCM::Configuration> object using the
C<get_config_for_profile> function.

=head1 INTERNAL INFRASTRUCTURE

=head2 Module variables

This module provides backup methods for several C<CAF> modules. They
will prevent tests from actually modifying the state of the system,
while allowing an NCM component to follow a realistic execution path.

These backups record what files are being written, what commands are
being run, and allow for inspection by a test.

This is done with several functions, see B<Redefined functions> below,
that control the following variables:

=over 4

=cut

package Test::Quattor;

use strict;
use warnings;
use CAF::FileWriter;
use CAF::Process;
use CAF::FileEditor;
use CAF::Application;
use IO::String;
use EDG::WP4::CCM::Configuration;
use EDG::WP4::CCM::CacheManager;
use EDG::WP4::CCM::Fetch;
use base 'Exporter';
use Cwd;
use Carp qw(carp croak);
use File::Path qw(make_path);

=pod

=item * C<%files_contents>

Contents of a file after it is closed. The keys of this hash are the
absolute paths to the files.

=cut

my %files_contents;

=pod

=item * C<%commands_run>

CAF::Process objects being associated to a command execution.

=cut

my %commands_run;

=pod

=item * C<%commands_status>

Desired exit status for a command. If the command is not present here,
it is assumed to succeed.

=cut

my %command_status;

=pod

=item * C<%desired_outputs>

When we know the component will call C<CAF::Process::output> and
friends, we prepare here an output that the component will have to
deal with.

=cut

my %desired_outputs;

=pod

=item * C<%desired_file_contents>

Optionally, initial contents for a file that should be "edited".

=cut

my %desired_file_contents;

my %configs;

our @EXPORT = qw(get_command set_file_contents get_file
		 get_config_for_profile set_command_status);

$main::this_app = CAF::Application->new('a', "--verbose", @ARGV);

sub prepare_profile_cache
{
    my ($profile) = @_;

    my $dir = getcwd();

    my $cache = "target/test/cache/$profile";
    make_path($cache);
    system("echo no > $cache/global.lock");
    system("echo 1 > $cache/current.cid");
    system("echo 1 > $cache/latest.cid");
    system(qq{cd src/test/resources &&
             panc -x json --output-dir=../../../target/test/profiles $profile.pan}) == 0
	or croak("Unable to compile profile $profile");
    my $f = EDG::WP4::CCM::Fetch->new({
				       FOREIGN => 0,
				       CONFIG => 'src/test/resources/ccm.cfg',
				       CACHE_ROOT => $cache,
				       PROFILE_URL => "file://$dir/target/test/profiles/$profile.json",
				       })
	or croak ("Couldn't create fetch object");
    $f->{CACHE_ROOT} = $cache;
    $f->fetchProfile() or croak "Unable to fetch profile $profile";

    my $cm =  EDG::WP4::CCM::CacheManager->new($cache);
    $configs{$profile} = $cm->getUnlockedConfiguration();
}


sub import
{
    my $class = shift;

    make_path("target/test/profiles");
    foreach my $pf (@_) {
	prepare_profile_cache($pf);
    }

    $class->SUPER::export_to_level(1, $class, @EXPORT);
}

=pod

=back

=head2 Redefined functions

In order to achieve this, the following functions are redefined
automatically:

=over

=cut

no warnings 'redefine';
no strict 'refs';

=pod

=item C<CAF::Process::{run,execute,output,trun,toutput}>

Prevent any command from being executed.

=cut

foreach my $method (qw(run execute trun)) {
    *{"CAF::Process::$method"} = sub {
	my $self = shift;
	my $cmd = join(" ", @{$self->{COMMAND}});
	$commands_run{$cmd} = { object => $self,
				method => $method
			      };
	if (exists($command_status{$cmd})) {
	    $? = $command_status{$cmd};
	} else {
	    $? = 0;
	}
	if ($self->{opts}->{stdout}) {
	    $self->{opts}->{stdout} = $desired_outputs{$cmd};
	}
	return 1;
    };
}

foreach my $method (qw(output toutput)) {
    *{"CAF::Process::$method"} = sub {
	my $self = shift;

	my $cmd = join(" ", @{$self->{COMMAND}});
	$commands_run{$cmd} = { object => $self,
				method => $method};
	$? = 0;
	return $desired_outputs{$cmd};
    };
}

=pod

=item C<CAF::FileWriter::open>

Overriding this function allows us to inspect its contents after the
unit under tests has released it.

=cut

*old_open = \&CAF::FileWriter::new;

*CAF::FileWriter::new = sub {
    my $f = old_open(@_);

    $files_contents{*$f->{filename}} = $f;
    return $f;
};

*CAF::FileWriter::open = \&CAF::FileWriter::new;

=pod

=item C<CAF::FileEditor::new>

It's just calling CAF::FileWriter::new, plus initialising its contnts
with the value of the appropriate entry in C<%desired_file_contents>

=cut

*CAF::FileEditor::new = sub {
    my $f = CAF::FileWriter::new(@_);
    $f->set_contents($desired_file_contents{*$f->{filename}});
    return $f;
};

*CAF::FileEditor::open = \&CAF::FileEditor::new;

=pod

=item C<IO::String::close>

Prevents the buffers from being released when explicitly closing a file.

=back

=cut


*IO::String::close = sub {};

use warnings 'redefine';

=pod

=head1 FUNCTIONS FOR EXTERNAL USE

The following functions are exported by default:

=over

=item C<get_file>

Returns the object that has manipulated C<$filename>

=cut

sub get_file
{
    my ($filename) = @_;

    if (exists($files_contents{$filename})) {
	return $files_contents{$filename};
    }
    return undef;
}

=pod

=item C<set_file_contents>

For file C<$filename>, sets the initial C<$contents> the component shuold see.

=cut

sub set_file_contents
{
    my ($filename, $contents) = @_;

    $desired_file_contents{$filename} = $contents;
}

=pod

=item C<get_command>

Returns all the information recorded about the execution of C<$cmd>,
if it has been executed. This is a hash reference in which the
C<object> element is the C<CAF::Process> object itself, and the
C<method> element is the function that executed the command.

=cut

sub get_command
{
    my ($cmd) = @_;

    if (exists($commands_run{$cmd})) {
	return $commands_run{$cmd};
    }
    return undef;
}

=pod

=item C<get_config_for_profile>

Returns a configuration object for the profile given as an
argument. The profile should be one of the arguments given to this
module when loading it.

=cut

sub get_config_for_profile
{
    my ($profile) = @_;

    return $configs{$profile};
}

sub set_command_status
{
    my ($cmd, $st) = @_;

    $command_status{$cmd} = $st;
}

1;

__END__

=pod

=back

=head1 BUGS

Probably many. It does quite a lot of internal black magic to make
your executions safe. Please ensure your component doesn't try to
outsmart the C<CAF> library and everything should be fine.

=cut
