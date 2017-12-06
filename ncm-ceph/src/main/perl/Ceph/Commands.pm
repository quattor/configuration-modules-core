#${PMpre} NCM::Component::Ceph::Commands${PMpost}

use 5.10.1;


# run a command and return the output
sub run_command {
    my ($self, $command, $msg, %opts ) = @_; 
    my $proc = CAF::Process->new(
        $command,
        log => $self,
        user => $opts{user},
        sensitive => $opts{sensitive},
    );
    my $output = $proc->output();
    my $ok = $? ? 0 : 1;
    chomp($output);

    my $fmsg = "$msg";
    $fmsg .= " as user $opts{user}" if (exists $opts{user});
    $fmsg .= " output: $output" if ($output && !$opts{sensitive});

    my $report = ($opts{test} || $ok) ? 'verbose' : 'error';
    $self->$report($ok ? ucfirst($fmsg) : "Failed to $fmsg");

    return wantarray ? ($ok, $output) : $ok;
}

1;

