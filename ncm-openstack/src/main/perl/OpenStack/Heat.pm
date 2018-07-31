#${PMpre} NCM::Component::OpenStack::Heat${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our @HEAT_DAEMONS_SERVER => qw(openstack-heat-api
                                        openstack-heat-api-cfn
                                        openstack-heat-engine);


=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{daemons} = [@HEAT_DAEMONS_SERVER];
}


=pod

=back

=cut

1;
