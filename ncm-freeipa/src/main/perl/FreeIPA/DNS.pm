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

    my $zone = $self->find_one("dnszone", $name);
    if ($zone) {
        $self->debug("Zone $name already exists.");
    } else {
        $self->debug("Adding dnszone $name");
        return $self->api_dnszone_add($name) ? $self->{result} : undef;
    }
}


=pod

=back

=cut


1;
