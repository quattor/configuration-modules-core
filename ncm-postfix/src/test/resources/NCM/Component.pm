=pod

=head1 DESCRIPTION

Backup module, mimicking the base class for all NCM components, but
with no real logic.

=cut

package NCM::Component;

use strict;
use warnings;
use parent 'CAF::Object';
use Template;

sub _initialize
{
    my ($self, $name, $log) = @_;

    $self->{name} = $name;
    $self->{log} = $log || $main::this_app;

    $self->{template} = Template->new(INCLUDE_PATH =>
				      'target/share/templates/quattor',
				      DEBUG => 'undef'
	);

    return 1;
}

sub template
{
    my $self = shift;
    return $self->{template};
}

no strict 'refs';
foreach my $i (qw(verbose error info ok debug)) {
    *{$i} = sub {
	my $self = shift;
	return $self->{log}->$i(@_) if $self->{log};
    }
}

1;
