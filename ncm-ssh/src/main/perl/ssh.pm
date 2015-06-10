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
use constant SSHD_CONFIG  => "/etc/ssh/sshd_config";
use constant SSH_CONFIG   => "/etc/ssh/ssh_config";
use constant SSH_VALIDATE => qw(/usr/sbin/sshd -t -f /proc/self/fd/0);

# Returns true if $file is a valid SSHD configuration file.
sub valid_sshd_file
{
    my ($self, $file) = @_;

    my $cmd = CAF::Process->new(
        [SSH_VALIDATE],
        log         => $self,
        stdin       => "$file",
        stderr      => \my $err,
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
        if ($cfg->{$option_set}) {
            $self->debug(1, "Processing $option_set");
            my $ssh_component_config = $cfg->{$option_set};
            while (my ($option, $val) = each(%$ssh_component_config)) {
                my $comment;
                if ($option_set eq 'comment_options') {
                    $comment = '#';
                } else {
                    $comment = '';
                }

                my $escaped_val = $val;
                $escaped_val =~ s{([?{}.()\[\]])}{\\$1}g;
                $fh->add_or_replace_lines(
                    qr{(?i)^\W*$option(?:\s+\S+)+}, qr{^\s*$comment\s*$option\s+$escaped_val\s*$},
                    "$comment$option $val\n",       ENDING_OF_FILE
                );
            }
        }
    }

    if ($validate && !$validate->($self, $fh)) {
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
        if ($self->handle_config_file(SSHD_CONFIG, 0600, $ssh_config->{daemon}, \&valid_sshd_file))
        {
            CAF::Process->new([qw(/sbin/service sshd condrestart)], log => $self)->run();
            if ($?) {
                $self->error("Unable to restart the sshd daemon");
                $ok = 0;
            }
        }
    }

    if ($ssh_config->{client}) {
        $self->handle_config_file(SSH_CONFIG, 0644, $ssh_config->{client});
    }
    return $ok;
}

1;    #required for Perl modules
