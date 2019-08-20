#${PMpre} NCM::Component::OpenStack::Cloudkitty${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our @CLOUDKITTY_DAEMONS_SERVER => qw(cloudkitty-processor httpd);
Readonly our $CLOUDKITTY_STORAGE_DB_COMMAND => "/usr/bin/cloudkitty-storage-init";

=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{manage} = "/usr/bin/cloudkitty-dbsync";
    $self->{daemons} = [@CLOUDKITTY_DAEMONS_SERVER];
    $self->{db_version} = ["version", "--module", "cloudkitty"];
    $self->{db_sync} = ["upgrade"];
}


=item pre_populate_service_database

Initializes C<Cloudkitty> storage backend for the C<OpenStack> rating service.

=cut

sub pre_populate_service_database
{
    my ($self) = @_;

    my $cmd = [$CLOUDKITTY_STORAGE_DB_COMMAND];
    $self->_do($cmd, "pre-populate Cloudkitty storage", sensitive => 0, user => 'cloudkitty')
        or return;

    return 1;
}

=pod

=back

=cut

1;
