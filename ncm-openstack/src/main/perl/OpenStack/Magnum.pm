#${PMpre} NCM::Component::OpenStack::Magnum${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our @MAGNUM_DAEMONS_SERVER => qw(openstack-magnum-api
                                        openstack-magnum-conductor);


=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{daemons} = [@MAGNUM_DAEMONS_SERVER];
    $self->{manage} = "/usr/bin/magnum-db-manage";
    $self->{db_version} = ["version"];
    $self->{db_sync} = ["upgrade"];
}


=pod

=back

=cut

1;
