#${PMpre} NCM::Component::OpenStack::Barbican${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;


=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;
    # Barbican only requires http service with wsgi setup
    $self->{daemons} = ['httpd'];
    $self->{db_version} = ["db", "version"];
    $self->{db_sync} = ["db", "upgrade"];
}


=pod

=back

=cut

1;
