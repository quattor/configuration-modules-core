#${PMpre} NCM::Component::OpenStack::Openrc${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;
Readonly our $CONFIG_FILE => "/root/admin-openrc.sh";

=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{sensitive} = 1;
    $self->{tt} = 'openrc';
    $self->{filename} = $CONFIG_FILE;
    $self->{daemons} = ['httpd'];
    $self->{user} = 'root';
}

=item _set_elpath

OpenRC is a special case, where type==flavour

=cut

sub _set_elpath
{
    my $self = shift;
    $self->{elpath} = "$self->{prefix}/$self->{type}";
}

=item populate_service_database

No database to populate

=cut

sub populate_service_database {return 1;};

=pod

=back

=cut

1;
