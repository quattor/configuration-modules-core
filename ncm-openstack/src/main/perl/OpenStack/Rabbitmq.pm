#${PMpre} NCM::Component::OpenStack::Rabbitmq${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $RABBIT_DB_MANAGE_COMMAND => "/usr/sbin/rabbitmqctl";

=head2 Methods

=over

=item _attrs

Override default attributes

=cut

sub _attrs
{
    my $self = shift;

    $self->{sensitive} = 1;
    delete $self->{daemons};
    $self->{user} = 'root';
    $self->{manage} = $RABBIT_DB_MANAGE_COMMAND;
    $self->{db_version} = ['list_user_permissions', $self->{tree}->{user}];
    $self->{db_sync} = ["add_user", $self->{tree}->{user}, $self->{tree}->{password}];
}

=item write_config_file

No config files to write

=cut

sub write_config_file {return 1;};


=item post_populate_service_database

Sets RabbitMQ permissions

=cut

sub post_populate_service_database
{
    my ($self) = @_;

    my $cmd = [$self->{manage}, "set_permissions", $self->{tree}->{user}, @{$self->{tree}->{permissions}}];
    my $msg = "Setting RabbitMQ permissions for $self->{tree}->{user} user";

    return $self->_do($cmd, $msg, user => undef, sensitive => 0);
}

=pod

=back

=cut

1;
