# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


# This component needs a 'oneadmin' user. 
# The user should be able to run these commands with sudo without password:
# /usr/bin/virsh secret-define --file /var/lib/one/templates/secret/secret_ceph.xml
# /usr/bin/virsh secret-set-value --secret $uuid --base64 $secret

package NCM::Component::OpenNebula::commands;

use strict;
use warnings;
use LC::Exception;
use LC::Find;
use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use File::Basename;
use Readonly;

Readonly::Array our @SSH_MULTIPLEX_OPTS => qw(-o ControlMaster=auto 
    -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r);
Readonly::Array our @SSH_COMMAND => qw(/usr/bin/ssh);
Readonly::Array my @VIRSH_COMMAND => qw(sudo /usr/bin/virsh);
Readonly::Array my @SU_ONEADMIN_COMMAND => qw(su - oneadmin -c);
Readonly::Array my @SSH_KEYGEN_COMMAND => qw(/usr/bin/ssh-keygen);
Readonly::Array my @SSH_KEYSCAN_COMMAND => qw(/usr/bin/ssh-keyscan);
Readonly::Array my @ONEUSER_PASS_COMMAND => qw(/usr/bin/oneuser passwd oneadmin);

my $sshcmd=[];


# Sub to set $sshcmd
sub set_ssh_command
{
    my ($self, $usemultiplex) = @_;
    push(@$sshcmd, @SSH_COMMAND);
    if ($usemultiplex) {
        $self->debug(2, 'Using SSH Multiplexing');
        push(@$sshcmd, @SSH_MULTIPLEX_OPTS);
    }
}

# Run a command and return the output
sub run_command {
    my ($self, $command, $secret) = @_;
    my ($cmd_output, $cmd_err, $cmd);
    my %opts = (stdout => \$cmd_output, stderr => \$cmd_err);
    $opts{log} = $self if !$secret;
    $cmd = CAF::Process->new($command, %opts);
    $cmd->execute();
    if (!$secret) {
        $self->verbose("Output: $cmd_output") if $cmd_output;
        if ($?) {
            $self->error("Command failed: $cmd_err");
            return;
        } else {
            $self->verbose("Stderr: $cmd_err");
        }
    }
    return wantarray ? ($cmd_output, $cmd_err) : ($cmd_output || "0E0");
}

# Run a command prefixed with virsh and return the output
sub run_virsh_as_oneadmin_with_ssh {
    my ($self, $command, $host, $secret, $ssh_options) = @_;
    $ssh_options = [] if (! defined($ssh_options));
    return $self->run_command_as_oneadmin([@$sshcmd, @$ssh_options, $host, @VIRSH_COMMAND, @$command], $secret);
}

# Run oneuser and return the output
sub run_oneuser_as_oneadmin_with_ssh {
    my ($self, $command, $host, $secret, $ssh_options) = @_;
    $ssh_options = [] if (! defined($ssh_options));
    return $self->run_command_as_oneadmin([@$sshcmd, @$ssh_options, $host, @ONEUSER_PASS_COMMAND, @$command], $secret);
}


# Checks for shell escapes
sub has_shell_escapes {
    my ($self, $cmd) = @_;
    if (grep(m{[;&>|"']}, @$cmd) ) {
        $self->error("Invalid shell escapes found in ", 
            join(" ", @$cmd));
        return 0;
    }
    return 1;
}

# Runs a command as the oneadmin user
sub run_command_as_oneadmin {
    my ($self, $command, $secret) = @_;
    
    $self->has_shell_escapes($command) or return; 
    $command = [join(' ',@$command)];
    return $self->run_command([@SU_ONEADMIN_COMMAND, @$command], $secret);
}

# Runs a command as oneadmin over ssh, optionally with options
sub run_command_as_oneadmin_with_ssh {
    my ($self, $command, $host, $secret, $ssh_options) = @_;
    $ssh_options = [] if (! defined($ssh_options));
    return $self->run_command_as_oneadmin([@$sshcmd, @$ssh_options, $host, @$command], $secret);
}

# Accept and add unknown keys if wanted
sub ssh_known_keys {
    my ($self, $host, $key_accept, $homedir) = @_; 
    if ($key_accept eq 'first'){
        # If not in known_host, scan key and add; else do nothing
        my $cmd = [@SSH_KEYGEN_COMMAND, '-F', $host];
        my $output = $self->run_command_as_oneadmin($cmd);
        # Count the lines of the output
        my $lines = $output =~ tr/\n//;
        if (!$lines) {
            $cmd = [@SSH_KEYSCAN_COMMAND, $host];
            my $key = $self->run_command_as_oneadmin($cmd);
            my $fh = CAF::FileEditor->open("$homedir/.ssh/known_hosts",
                                           log => $self);
            $fh->head_print($key);
            $fh->close();
        }
    } elsif ($key_accept eq 'always'){
        # SSH into machine with -o StrictHostKeyChecking=no
        # dummy ssh does the trick
        $self->run_command_as_oneadmin_with_ssh(['uname'], $host, ['-o', 'StrictHostKeyChecking=no']);
    }   
}

# check if host is reachable
sub can_connect_to_host {
    my ($self, $host) = @_;
    $self->ssh_known_keys($host, 'always', '~');
    return $self->run_command_as_oneadmin_with_ssh(['uname'], $host);
}

1;
