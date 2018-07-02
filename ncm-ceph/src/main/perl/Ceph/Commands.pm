#${PMpre} NCM::Component::Ceph::Commands${PMpost}

use CAF::Path;

Readonly::Array our @SSH_MULTIPLEX_OPTS =>
    qw(-o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r);
Readonly::Array our @SSH_COMMAND => qw(/usr/bin/ssh);

# run a command and return the output
sub run_command
{
    my ($self, $command, $msg, %opts ) = @_;

    my ($stdout, $stderr, $stderrref);
    my $stdoutref = \$stdout;
    if ($opts{nostderr}) {
        $stderrref = \$stderr;
    } else {
        $stderrref = 'stdout';
    }

    my $proc = CAF::Process->new(
        $command,
        log => $self,
        user => $opts{user},
        sensitive => $opts{sensitive},
        timeout => $opts{timeout} || 0, # default 0
        stdout => $stdoutref,
        stderr => $stderrref,
    );

    if ($opts{printonly}) {
        $self->info("$proc");
        return 1;
    }
    $proc->execute();
    my $ok = $? ? 0 : 1;
    my $output = $$stdoutref;

    my $fmsg = "$msg";
    $fmsg .= " as user $opts{user}" if (exists $opts{user});
    $fmsg .= " with timeout $opts{timeout}" if (exists $opts{timeout});
    $fmsg .= " output: $output" if ($output && !$opts{sensitive});
    $fmsg .= " ignored stderr: $$stderrref" if ($opts{nostderr});

    my $report = ($opts{test} || $ok) ? 'verbose' : 'error';
    $self->$report($ok ? ucfirst($fmsg) : "Failed to $fmsg");

    return wantarray ? ($ok, $output) : $ok;
}

# Wrapper around CAF::Path->file_exists with reporting
sub file_exists
{
    my ($self, $file, %opts) = @_;

    my $ok = CAF::Path->file_exists($file);
    my $report = ($opts{test} || $ok) ? 'verbose' : 'error';
    $self->$report($ok ? "File $file exists" : "File $file does not exists");

    return $ok;
}

# Runs a command as the ceph user
sub run_command_as_ceph
{
    my ($self, $command, $msg, %opts) = @_;

    $command = [join(' ',@$command)];
    return $self->run_command([qw(su - ceph -c), @$command], $msg, %opts);
}


# run a command prefixed with ceph and return the output in json format
sub run_ceph_command
{
    my ($self, $command, $msg, %opts) = @_;
    return $self->run_command([qw(/usr/bin/ceph -f json), @$command], $msg, %opts);
}

# run a command prefixed with ceph-deploy and return the output (no json)
sub run_ceph_deploy_command
{
    my ($self, $command, $msg, %opts) = @_;
    if ($opts{overwritecfg}) {
        unshift (@$command, '--overwrite-conf');
    }
    # run as user configured for 'ceph-deploy'
    return $self->run_command_as_ceph(['/usr/bin/ceph-deploy', @$command], $msg, %opts);
}

# Runs a command as ceph over ssh, optionally with options
sub run_command_as_ceph_with_ssh
{
    my ($self, $command, $host, $msg, %opts) = @_;
    $opts{ssh_options} = [] if (! defined($opts{ssh_options}));
    my $sshcmd = [@SSH_COMMAND];
    if ($self->{ssh_multiplex}) {
        $self->debug(2, 'Using SSH Multiplexing');
        push(@$sshcmd, @SSH_MULTIPLEX_OPTS);
    }
    return $self->run_command_as_ceph([@$sshcmd, @{$opts{ssh_options}}, $host, @$command], $msg, %opts);
}


# Accept and add unknown keys if wanted
sub ssh_known_keys
{
    my ($self, $host, $key_accept, $cephusr) = @_;
    return 1 if !defined($key_accept);
    if ($key_accept eq 'first'){
        # If not in known_host, scan key and add; else do nothing
        my $cmd = ['/usr/bin/ssh-keygen', '-F', $host];
        my ($ec, $output) = $self->run_command_as_ceph($cmd, "scan ssh knownhosts for $host");
        # Count the lines of the output
        my $lines = $output =~ tr/\n//;
        if (!$lines) {
            $cmd = ['/usr/bin/ssh-keyscan', $host];
            my ($ec, $key) = $self->run_command_as_ceph($cmd, "scan ssh key for $host");
            my $fh = CAF::FileEditor->open("$cephusr->{homeDir}/.ssh/known_hosts",
                                            log => $self,
                                            owner => $cephusr->{uid},
                                            group => $cephusr->{gid},
                                        );
            $fh->head_print($key);
            $fh->close();
        }
    } elsif ($key_accept eq 'always'){
        # SSH into machine with -o StrictHostKeyChecking=no
        # dummy ssh does the trick
        $self->run_command_as_ceph_with_ssh(['uname'], $host, "connect with ssh to $host",
            ssh_options => ['-o', 'StrictHostKeyChecking=no']);
    } else {
        $self->debug(3, "SSH hostkeys not managed");
    }
    return 1;
}

sub test_host_connection
{
    my ($self, $host, $key_accept, $cephusr) = @_;
    $self->ssh_known_keys($host, $key_accept, $cephusr);
    return $self->run_command_as_ceph_with_ssh(['uname'], $host, 'connect with ssh');
}

1;
