# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::nsca;

use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Property;
use NCM::Check;
use FileHandle;
use LC::Process qw (execute);
use LC::Exception qw (throw_error);

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use constant DAEMON_PATH => '/software/components/nsca/daemon';
use constant DAEMON_CFG => '/etc/nagios/nsca.cfg';

use constant SEND_PATH => '/software/components/nsca/send';
use constant SEND_CFG => '/etc/nagios/send_nsca.cfg';


sub Configure
{
    my ($self, $config) = @_;

    # daemon configuration
    if ( $config->elementExists(DAEMON_PATH) ) {
        my $st = $config->getElement(DAEMON_PATH)->getTree;
        my $fh = FileHandle->new (DAEMON_CFG, 'w');
        unless ($fh) {
            throw_error ("Couldn't open " . DAEMON_CFG);
            return 0;
        }

        $fh->print ("# nsca.cfg\n",
            "# written by ncm-nsca. Do not edit!\n",
            "pid_file=$st->{pid_file}\n",
            "server_port=$st->{server_port}\n",
            "nsca_user=$st->{user}\n",
            "nsca_group=$st->{group}\n",
            "debug=$st->{debug}\n",
            "command_file=$st->{command_file}\n",
            "alternate_dump_file=$st->{alt_dump_file}\n",
            "aggregate_writes=$st->{aggregate_writes}\n",
            "append_to_file=$st->{append_to_file}\n",
            "max_packet_age=$st->{max_packet_age}\n",
            "password=$st->{password}\n",
            "decryption_method=$st->{decryption_method}\n",
        );

        $fh->print ("server_address=$st->{server_address}\n") if $st->{server_address};
        $fh->print ("nsca_chroot=$st->{chroot}\n") if $st->{chroot};

        my $uid = (getpwnam ($st->{user}))[2];
        my $gid = (getpwnam ($st->{group}))[3];
        chown ($uid, $gid, DAEMON_CFG);
        chmod (0640, DAEMON_CFG);

        execute (["/etc/init.d/nsca", "restart"]);
    }

    # send_nsca config
    if ( $config->elementExists(SEND_PATH) ) {
        my $st = $config->getElement(SEND_PATH)->getTree;
        my $fh = FileHandle->new (SEND_CFG, 'w');
        unless ($fh) {
            throw_error ("Couldn't open " . SEND_CFG);
            return 0;
        }

        $fh->print ("# send_nsca.cfg\n",
            "password=$st->{password}\n",
            "encryption_method=$st->{decryption_method}\n",
        );

        chmod (0640, SEND_CFG);
    }

    return 1;
}
