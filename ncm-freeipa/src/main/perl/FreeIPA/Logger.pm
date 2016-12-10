#${PMpre} NCM::Component::FreeIPA::Logger${PMpost}

=head1 NAME

C<NCM::Component::FreeIPA::Logger> provides a log4perl compatible logger
using C<CAf::Reporter>.

=head2 Public methods

=over

=item new

Creates simple instance wrapper arond mandatory argument C<reporter>,
a C<CAF::Reporter> instance.

=cut

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {}; # here, it gives a reference on a hash
    bless $self, $class;

    $self->{reporter} = shift;

    return $self;
};


# debug logger, maps to C<CAF::Reporter> debug level 1
sub debug
{
    my $self = shift;
    return $self->{reporter}->debug(1, @_);
}

# Mock basic methods of Log4Perl getLogger instance
no strict 'refs'; ## no critic
foreach my $i (qw(error warn info)) {
    *{$i} = sub {
        my ($self, @args) = @_;
        return $self->{reporter}->$i(@args);
    };
}
use strict 'refs';

=pod

=back

=cut

1;
