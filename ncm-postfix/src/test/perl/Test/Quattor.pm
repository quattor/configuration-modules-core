=pod

=head1 DESCRIPTION

C<Test::Quattor>

Backup methods for several C<CAF> modules, that will prevent tests
from actually modifying the state of the system, while allowing an NCM
component to follow a realistic execution path.

These backups record what files are being written, what commands are
being run, and allow for inspection by a test.

For now, this is done via a few global variables:

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
use EDG::WP4::CCM::Fetch;
use Exporter;
use Cwd;
use Carp qw(croak);
use File::Path qw(make_path);

=pod

=item * C<%files_contents>

Contents of a file after it is closed. The keys of this hash are the
absolute paths to the files.

=cut

our %files_contents;

=pod

=item * C<%commands_run>

CAF::Process objects being associated to a command execution.

=cut

our %commands_run;

=pod

=item * C<%desired_outputs>

When we know the component will call C<CAF::Process::output> and
friends, we prepare here an output that the component will have to
deal with.

=cut

our %desired_outputs;

=pod

=item * C<%desired_file_contents>

Optionally, initial contents for a file that should be "edited".

=cut

our %desired_file_contents;

our @EXPORT_OK = qw(%files_contents %commands_run);

$main::this_app = CAF::Application->new('a', "--verbose", @ARGV);

no warnings 'redefine';

=pod

=back

=head2 Redefined functions

In order to achieve this, the following functions are redefined
automatically:

=over

=cut

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

sub prepare_profile_configs
{
    my ($profile) = @_;

    my $dir = getcwd();

    make_path("target/test/$profile");
    system(q{cd src/test/resources &&
             panc -x json --output-dir=../../../target/test/$profile $profile.pan});
    my $f = EDG::WP4::CCM::Fetch->new({
				       FOREIGN => 0,
				       PROFILE_URL => "file://$dir/target/test/$profile/$profile.json",
				       CACHE_ROOT => "target/test/cache/$profile",
				       TIMEOUT => 1,
				       RETRIES => 1,
				       });
    $f->fetchProfile() or croak "Unable to fetch profile $profile";
}

1;

__END__

=pod

=back

=cut
