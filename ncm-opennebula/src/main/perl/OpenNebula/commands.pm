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

Readonly::Array my @SSH_COMMAND => (
'/usr/bin/ssh', '-o', 'ControlMaster=auto', 
'-o', 'ControlPath=/tmp/ssh_mux_%h_%p_%r'
);
Readonly::Array my @VIRSH_COMMAND => ('/usr/bin/virsh');
Readonly::Array my @SU_ONEADMIN_COMMAND => ('su - oneadmin -c');
Readonly::Array my @SSH_KEYGEN_COMMAND => ('/usr/bin/ssh-keygen');
Readonly::Array my @SSH_KEYSCAN_COMMAND => ('/usr/bin/ssh-keyscan');

# Run a command and return the output
sub run_command {
    my ($self, $command, $secret) = @_;
    my ($cmd_output, $cmd_err, $cmd);
    if (! defined($secret)) {
        $cmd = CAF::Process->new($command, log => $self, stdout => \$cmd_output, stderr => \$cmd_err);
    } else {
        $cmd = CAF::Process->new($command, stdout => \$cmd_output, stderr => \$cmd_err);
    }
    $cmd->execute();
    if ($?) {
        $self->error("Command failed. Error Message: $cmd_err");
        if ($cmd_output) {
            $self->verbose("Command output: $cmd_output");
        }
        return;
    } elsif (! defined($secret)) {
        if ($cmd_output) {
            $self->verbose("Command output: $cmd_output");
        }
        if ($cmd_err) {
            $self->verbose("Command stderr output: $cmd_err");
        }    
    }
    return wantarray ? ($cmd_output, $cmd_err) : ($cmd_output || "0E0");
}

# Run a command prefixed with virsh and return the output
sub run_virsh_command {
    my ($self, $command) = @_;
    return $self->run_command([@VIRSH_COMMAND, @$command]);
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
    return $self->run_command_as_oneadmin([@SSH_COMMAND, @$ssh_options, $host, @$command], $secret);
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
sub test_host_connection {
    my ($self, $host) = @_;
    $self->ssh_known_keys($host, 'always', '~');
    return $self->run_command_as_oneadmin_with_ssh(['uname'], $host);
}

1;
