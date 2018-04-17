#${PMpre} NCM::Component::OpenStack::Manila${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our @MANILA_DAEMONS_SERVER => qw(openstack-manila-api
                                        openstack-manila-scheduler
                                        openstack-manila-share);


=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{daemons} = [@MANILA_DAEMONS_SERVER];
    $self->{db_version} = ["db", "version"];
    $self->{db_sync} = ["db", "sync"];
}


=pod

=back

=cut

1;
