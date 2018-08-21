#${PMpre} NCM::Component::OpenStack::Murano${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our @MURANO_DAEMONS_SERVER => qw(murano-api
                                        murano-engine);


=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{manage} = "/usr/bin/murano-db-manage";
    $self->{daemons} = [@MURANO_DAEMONS_SERVER];
    $self->{db_version} = ["version"];
    $self->{db_sync} = ["upgrade"];
}


=pod

=back

=cut

1;
