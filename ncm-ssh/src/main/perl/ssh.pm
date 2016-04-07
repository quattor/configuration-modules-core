# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM SSH configuration component
#

package NCM::Component::ssh;

#
# a few standard statements, mandatory for all components
#

use strict;
use base qw(NCM::Component);

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

use CAF::Process;
use CAF::FileEditor;
use constant DEFAULT_SSHD_CONFIG  => "/etc/ssh/sshd_config";
use constant DEFAULT_SSHD_PATH    => "/usr/sbin/sshd";
use constant DEFAULT_SSH_CONFIG   => "/etc/ssh/ssh_config";
use constant SSHD_CONFIG_MULTILINE => qw(HostKey AcceptEnv ListenAddress);

# Returns true if $file is a valid SSHD configuration file.
sub valid_sshd_file
{
    my ($self, $file, $cfg) = @_;

    my $sshd_bin = $cfg->{sshd_path} || DEFAULT_SSHD_PATH;
    
    if (defined($cfg->{always_validate}) && !$cfg->{always_validate} && ! -x $sshd_bin) {
        $self->info("$sshd_bin doesn't exist with always_validate=0, skipping sshd config test.");
        return 1;
    }

    # Use /dev/stdin, instead of /proc/self/fd/0 (which is used in some other components).
    # This is because /proc/self/fd/0 does not exist on Solaris. 
    my $cmdline = [ $sshd_bin, '-t', '-f', '/dev/stdin' ];

    my $cmd = CAF::Process->new(
        $cmdline,
        log         => $self,
        stderr      => \my $err,
        stdin       => "$file",
        keeps_state => 1
    );

    $cmd->execute();

    if ($?) {
        $self->error("Invalid configuration file: $err");
        return 0;
    }
    $self->warn("Non-fatal issues in the configuration file: $err") if $err;
    return 1;
}

#
# Process options for SSH daemon and client: processing is almost
# identical for both.  Returns whether or not the file changed, so
# that the caller may restart the daemon.
#
# Takes an optional parameter to validate the generated file.
sub handle_config_file
{
    my ($self, $filename, $mode, $cfg, $validate) = @_;

    my $fh = CAF::FileEditor->new(
        $filename,
        log    => $self,
        mode   => $mode,
        backup => '.old'
    );

    foreach my $option_set (qw(comment_options options)) {
        next if (! $cfg->{$option_set});

        $self->debug(1, "Processing $option_set");
        my $comment = $option_set eq 'comment_options' ? '#' : '';
        foreach my $option (sort keys %{$cfg->{$option_set}}) {
            my $val = $cfg->{$option_set}->{$option};
            my $ref = ref($val);
            if($ref) {
                if($ref eq 'ARRAY') {
                    if (grep {$_ eq $option} SSHD_CONFIG_MULTILINE) {
                        # remove any existing line for this option
                        # then add the options back in at the end of the file
                        $fh->remove_lines(qr{(?i)^\W*$option(?:\s+\S+)+}, qr{^#});
                        foreach my $multival (@$val) {
                            print $fh "$option $multival\n";
                        }
                        next;        
                    }
                    $val = join(',', @$val);
                } else {
                    $self->error("Unsupported value reference $ref for option $option.",
                                 " (Possibly bug in profile/schema).");
                    next;
                }
            }
            my $escaped_val = $val;
            $escaped_val =~ s{([?{}.()\[\]])}{\\$1}g;
            $fh->add_or_replace_lines(
                qr{(?i)^\W*$option(?:\s+\S+)+}, qr{^\s*$comment\s*$option\s+$escaped_val\s*$},
                "$comment$option $val\n",
                ENDING_OF_FILE
                );
        }
    }

    if ($validate && !$validate->($self, $fh, $cfg)) {
        $fh->cancel();
    }

    return $fh->close();
}

sub Configure
{
    my ($self, $config) = @_;

    # Retrieve configuration and do some initializations
    # Define paths for convenience.
    my $base       = "/software/components/ssh";
    my $ssh_config = $config->getElement($base)->getTree();
    my $ok         = 1;

    if ($ssh_config->{daemon}) {
        if ($self->handle_config_file($ssh_config->{daemon}->{config_path} || DEFAULT_SSHD_CONFIG,
                                      0600,
                                      $ssh_config->{daemon},
                                      \&valid_sshd_file))
        {
            CAF::Process->new([qw(/sbin/service sshd condrestart)], log => $self)->run();
            if ($?) {
                $self->error("Unable to restart the sshd daemon");
                $ok = 0;
            }
        }
    }

    if ($ssh_config->{client}) {
        $self->handle_config_file($ssh_config->{client}->{config_path} || DEFAULT_SSH_CONFIG,
                                  0644,
                                  $ssh_config->{client});
    }
    return $ok;
}

1;    #required for Perl modules
