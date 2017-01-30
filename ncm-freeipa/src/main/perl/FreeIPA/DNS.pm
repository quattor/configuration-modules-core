#${PMpre} NCM::Component::FreeIPA::DNS${PMpost}

use Readonly;

=head1 NAME

NCM::Component::FreeIPA::DNS adds DNS related methods to
L<NCM::Component::FreeIPA::Client>.

=head2 Public methods

=over

=item add_dnszone

Add a DNS zone with name C<name>.

=cut

sub add_dnszone
{
    my ($self, $name) = @_;

    return $self->do_one('dnszone', 'add', $name);
};

=pod

=back

=cut


1;
