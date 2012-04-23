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

use Exporter;

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

our @EXPORT_OK = qw(%files_contents %commands_run);



$main::this_app = CAF::Application->new('a', @ARGV);

no warnings 'redefine';

=pod

=back

=head2 Redefined functions

In order to achieve this, the following functions are redefined
automatically:

=over

=item C<CAF::FileWriter::open>

Prevents any files from being actually written, and allows the object
to be inspected afterwards.

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

*old_open = \&CAF::FileWriter::new;

*CAF::FileWriter::new = sub {
    my $f = old_open(@_);

    $files_contents{*$f->{filename}} = $f;
    return $f;
};

*CAF::FileWriter::open = \&CAF::FileWriter::new;

#*CAF::FileWriter::new = \&CAF::FileWriter::open;

1;
