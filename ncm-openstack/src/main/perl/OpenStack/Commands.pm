#${PMpre} NCM::Component::OpenStack::Commands${PMpost}

use LC::Exception;
use LC::Find;
use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use File::Basename;
use Readonly;

# Keystone manage commands
# More info: https://docs.openstack.org/keystone/latest/cli/index.html#keystone-manage
Readonly::Array my @KEYSTONE_FERNET_SETUP => qw(/usr/bin/keystone-manage 
    fernet_setup --keystone-user keystone --keystone-group keystone);
Readonly::Array my @KEYSTONE_CREDENTIAL_SETUP => qw(/usr/bin/keystone-manage credential_setup 
    --keystone-user keystone --keystone-group keystone);
Readonly::Array my @SU_COMMAND => qw(su -s /bin/sh -c);
Readonly::Array my @KEYSTONE_BOOTSTRAP_URL => qw(/usr/bin/keystone-manage bootstrap);


=head1 NAME

C<NCM::Component::OpenStack::Commands> Configuration module for OpenStack

=head1 DESCRIPTION

Configuration module for C<OpenStack>. Executes the required ssh commands
to populate the required service databases or bootstrap the Keystone Identity service.

This component needs at least a 'keystone' user.

=over

=back

=head2 Public methods

=over


=item run_command

Executes a command and return the output.
Returns sdout and stderr array.

=cut

sub run_command
{
    my ($self, $command, $secret) = @_;
    my ($cmd_output, $cmd_err, $cmd);
    my %opts = (stdout => \$cmd_output, stderr => \$cmd_err);
    $opts{log} = $self if !$secret;
    $cmd = CAF::Process->new($command, %opts);
    $cmd->execute();
    if (!$secret) {
        $self->verbose("Output: $cmd_output") if $cmd_output;
    }
    if ($?) {
        $self->error("Command failed: $cmd_err");
        return;
    } else {
        $self->verbose("Stderr: $cmd_err") if defined($cmd_err);
    }
    return wantarray ? ($cmd_output, $cmd_err) : ($cmd_output || "0E0");
}


=item run_command_as_openstack_user

Executes a command as an specific C<OpenStack> user.

=cut

sub run_command_as_openstack_user
{
    my ($self, $command, $user) = @_;
    return $self->run_command([@SU_COMMAND, $command, $user], 0);
}

=item run_command_as_root

Executes a command as root.

=cut

sub run_command_as_root
{
    my ($self, $command, $secret) = @_;

    $command = [join(' ', @$command)];
    return $self->run_command([@$command], $secret);
}


=item run_service_db_sync

Executes C<db_sync> command as C<OpenStack> 
service user and returns the output.

=cut

sub run_service_db_sync
{
    my ($self, $command, $user) = @_;

    $command = join(' ', $command, "db_sync");
    return $self->run_command_as_openstack_user($command, $user);
}


=item run_fernet_setup

Executes C<keystone-manage> fernet_setup command as root.

=cut

sub run_fernet_setup
{
    my ($self, $secret) = @_;
    return $self->run_command_as_root([@KEYSTONE_FERNET_SETUP], $secret);
}

=item run_credential_setup

Executes C<keystone-manage> credential_setup command as root.

=cut

sub run_credential_setup
{
    my ($self, $secret) = @_;
    return $self->run_command_as_root([@KEYSTONE_CREDENTIAL_SETUP], $secret);
}


=item run_url_bootstrap

Executes C<keystone-manage> identity urls bootstrap.

=cut

sub run_url_bootstrap
{
    my ($self, $command) = @_;
    return $self->run_command_as_root([@KEYSTONE_BOOTSTRAP_URL, @$command], 1);
}


=pod

=back

=cut

1;
