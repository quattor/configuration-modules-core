# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


# This component needs a 'oneadmin' user. 
# The user should be able to run these commands with sudo without password:
# /usr/sbin/service libvirtd restart
# /usr/sbin/service libvirt-guests restart
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

Readonly::Array our @SSH_COMMAND => (
'/usr/bin/ssh', '-o', 'ControlMaster=auto', 
'-o', 'ControlPath=/tmp/ssh_mux_%h_%p_%r'
);

# Run a command and return the output
sub run_command {
    my ($self, $command) = @_;
    my ($cmd_output, $cmd_err);
    my $cmd = CAF::Process->new($command, log => $self, 
        stdout => \$cmd_output, stderr => \$cmd_err);
    $cmd->execute();
    if ($?) {
        $self->error("Command failed. Error Message: $cmd_err");
        if ($cmd_output) {
            $self->verbose("Command output: $cmd_output");
        }
        return;
    } else {
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
    return $self->run_command([qw(/usr/bin/virsh), @$command]);
}

# Restart libvirtd service after qemu.cfg changes
sub run_daemon_libvirtd_command {
    my ($self, $command) = @_;
    return $self->run_command([qw(/sbin/service libvirtd), @$command]);
}

# Restart libvirt-guests service after qemu.cfg changes
sub run_daemon_libvirt_guest_command {
    my ($self, $command) = @_;
    return $self->run_command([qw(/sbin/service libvirt-guests), @$command]);
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
    my ($self, $command, $dir) = @_;
    
    $self->has_shell_escapes($command) or return; 
    if ($dir) {
        $self->has_shell_escapes([$dir]) or return;
        unshift (@$command, ('cd', $dir, '&&'));
    }
    $command = [join(' ',@$command)];
    return $self->run_command([qw(su - oneadmin -c), @$command]);
}

# Runs a command as oneadmin over ssh, optionally with options
sub run_command_as_oneadmin_with_ssh {
    my ($self, $command, $host, $ssh_options) = @_;
    $ssh_options = [] if (! defined($ssh_options));
    return $self->run_command_as_oneadmin([@SSH_COMMAND, @$ssh_options, $host, @$command]);
}

# Accept and add unknown keys if wanted
sub ssh_known_keys {
    my ($self, $host, $key_accept, $homedir) = @_; 
    if ($key_accept eq 'first'){
        # If not in known_host, scan key and add; else do nothing
        my $cmd = ['/usr/bin/ssh-keygen', '-F', $host];
        my $output = $self->run_command_as_oneadmin($cmd);
        #Count the lines of the output
        my $lines = $output =~ tr/\n//;
        if (!$lines) {
            $cmd = ['/usr/bin/ssh-keyscan', $host];
            my $key = $self->run_command_as_oneadmin($cmd);
            my $fh = CAF::FileEditor->open("$homedir/.ssh/known_hosts",
                                           log => $self);
            $fh->head_print($key);
            $fh->close()
        }
    } elsif ($key_accept eq 'always'){
        # SSH into machine with -o StrictHostKeyChecking=no
        # dummy ssh does the trick
        $self->run_command_as_oneadmin_with_ssh(['uname'], $host, ['-o', 'StrictHostKeyChecking=no']);
    }   
}

#check if host is reachable
sub test_host_connection {
    my ($self, $host) = @_;
    $self->ssh_known_keys($host, 'always', '~');
    return $self->run_command_as_oneadmin_with_ssh(['uname'], $host);
}

1;
