#${PMpre} NCM::Component::FreeIPA::Service${PMpost}

use Readonly;

=head1 NAME

NCM::Component::FreeIPA::Service adds service related methods to
L<NCM::Component::FreeIPA::Client>.

=head2 Public methods

=over

=item add_service

Add a service with name C<name>.

=cut

sub add_service
{
    my ($self, $name) = @_;

    return $self->do_one('service', 'add', $name);
};

=item add_service_host

Add a per-host service C<name> for host C<host>
(actual service name will C<<<name>/<host>>>).

Add host C<host> to list of hosts that can manage this service.

=cut

sub add_service_host
{
    my ($self, $name, $host) = @_;

    my $fname = "$name/$host";

    $self->add_service($fname);

    $self->do_one('service', 'allow_create_keytab', $fname, host => [$host]);
    return $self->do_one('service', 'allow_retrieve_keytab', $fname, host => [$host]);
}

=item service_has_keytab

Check if a keytab is already made for service with C<name>.

=cut

sub service_has_keytab
{
    my ($self, $name) = @_;

    my $res = $self->do_one('service', 'show', $name);
    return $res->{has_keytab} ? 1 : 0;
}

=pod

=back

=cut


1;
