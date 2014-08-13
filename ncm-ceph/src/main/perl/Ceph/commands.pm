# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


# This component needs a 'ceph' user. 
# The user should be able to run these commands with sudo without password:
# /usr/bin/ceph-deploy
# /usr/bin/python -c import sys;exec(eval(sys.stdin.readline()))
# /usr/bin/python -u -c import sys;exec(eval(sys.stdin.readline()))
# /bin/mkdir
#

package NCM::Component::Ceph::commands;

use 5.10.1;
use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use LC::Exception;
use LC::Find;

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
# taint-safe since 1.23;
# Packages @ http://www.city-fan.org/ftp/contrib/perl-modules/RPMS.rhel6/ 
# Attention: Package has some versions like 1.2101 and 1.2102 .. 
use File::Basename;
use Git::Repository;
our $EC=LC::Exception::Context->new->will_store_all;

use Readonly;
Readonly::Array our @SSH_COMMAND => (
'/usr/bin/ssh', '-o', 'ControlMaster=auto', 
'-o', 'ControlPersist=600', '-o', 'ControlPath=/tmp/ssh_mux_%h_%p_%r'
);

#set the working cluster, (if not given, use the default cluster 'ceph')
sub use_cluster {
    my ($self, $cluster) = @_;
    $cluster ||= 'ceph';
    if ($cluster ne 'ceph') {
        $self->error("Not yet implemented!"); 
        return 0;
    }
    $self->{cluster} = $cluster;
    return 1;
}

# run a command and return the output
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
    #return $cmd_output || "0 but true";
    return wantarray ? ($cmd_output, $cmd_err) : ($cmd_output || "0E0");
}

# run a command prefixed with ceph and return the output in json format
sub run_ceph_command {
    my ($self, $command) = @_;
    return $self->run_command([qw(/usr/bin/ceph -f json --cluster), $self->{cluster}, @$command]);
}

sub run_daemon_command {
    my ($self, $command) = @_;
    return $self->run_command([qw(/sbin/service ceph), @$command]);
}

#checks for shell escapes
sub has_shell_escapes {
    my ($self, $cmd) = @_;
    if (grep(m{[;&>|"']}, @$cmd) ) {
        $self->error("Invalid shell escapes found in ", 
            join(" ", @$cmd));
        return 0;
    }
    return 1;
}
    
#Runs a command as the ceph user
sub run_command_as_ceph {
    my ($self, $command, $dir) = @_;
    
    $self->has_shell_escapes($command) or return; 
    if ($dir) {
        $self->has_shell_escapes([$dir]) or return;
        unshift (@$command, ('cd', $dir, '&&'));
    }
    $command = [join(' ',@$command)];
    return $self->run_command([qw(su - ceph -c), @$command]);
}

# Runs a command as ceph over ssh, optionally with options
sub run_command_as_ceph_with_ssh {
    my ($self, $command, $host, $ssh_options) = @_;
    $ssh_options = [] if (! defined($ssh_options));
    return $self->run_command_as_ceph([@SSH_COMMAND, @$ssh_options, $host, @$command]);
}

# run a command prefixed with ceph-deploy and return the output (no json)
sub run_ceph_deploy_command {
    my ($self, $command, $dir, $overwrite) = @_;
    # run as user configured for 'ceph-deploy'
    if ($overwrite) {
        unshift (@$command, '--overwrite-conf');
    }
    return $self->run_command_as_ceph([qw(/usr/bin/ceph-deploy --cluster), $self->{cluster}, @$command], $dir);
}

# Accept and add unknown keys if wanted
sub ssh_known_keys {
    my ($self, $host, $key_accept, $homedir) = @_; 
    if ($key_accept eq 'first'){
        # If not in known_host, scan key and add; else do nothing
        my $cmd = ['/usr/bin/ssh-keygen', '-F', $host];
        my $output = $self->run_command_as_ceph($cmd);
        #Count the lines of the output
        my $lines = $output =~ tr/\n//;
        if (!$lines) {
            $cmd = ['/usr/bin/ssh-keyscan', $host];
            my $key = $self->run_command_as_ceph($cmd);
            my $fh = CAF::FileEditor->open("$homedir/.ssh/known_hosts",
                                           log => $self);
            $fh->head_print($key);
            $fh->close()
        }
    } elsif ($key_accept eq 'always'){
        # SSH into machine with -o StrictHostKeyChecking=no
        # dummy ssh does the trick
        $self->run_command_as_ceph_with_ssh(['uname'], $host, ['-o', 'StrictHostKeyChecking=no']);
    }   
}



# Print out the commands that should be run manually
sub print_cmds {
    my ($self, $cmds) = @_;
    if ($cmds && @{$cmds}) {
        $self->info("Commands to be run manually (as ceph user):");
        while (my $cmd = shift @{$cmds}) {
            $self->info(join(" ", @$cmd));
        }
    }
}

# Write the config file
sub write_config {
    my ($self, $cfg, $cfgfile ) = @_; 
    my $tinycfg = Config::Tiny->new;
    my $config = { %$cfg };
    foreach my $key (%{$config}) {
        if (ref($config->{$key}) eq 'ARRAY'){ #For mon_initial_members
            $config->{$key} = join(', ',@{$config->{$key}});
            $self->debug(3,"Array converted to string:", $config->{$key});
        }
    }   
    $tinycfg->{global} = $config;
    if (!$tinycfg->write($cfgfile)) {
        $self->error("Could not write config file $cfgfile: $!", "Exitcode: $?"); 
        return 0;
    }   
    $self->debug(2,"content written to config file $cfgfile");
    return 1;
}

# Adds and commits a file to the repo
# working_dir may be a subdir, 
# file can be absolute or relative to working copy
sub git_commit {
    my ($self, $work_tree, $file, $message) = @_;
    my $gitr = Git::Repository->new( work_tree => $work_tree );
    $gitr->run( add => $file );
    $gitr->run( commit => '-m', $message ) or return 0;    
    return 1;    
}

1; # Required for perl module!
