#${PMpre} NCM::Component::nsca${PMpost}

use CAF::FileWriter;
use CAF::Service;

use parent qw (NCM::Component);

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

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
        my $uid = (getpwnam ($st->{user}))[2];
        my $gid = (getpwnam ($st->{group}))[3];

        my $fh = CAF::FileWriter->new(DAEMON_CFG,
                                      owner => $uid,
                                      group => $gid,
                                      mode => 0640,
                                      log => $self);

        print $fh "# nsca.cfg\n",
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
            "decryption_method=$st->{decryption_method}\n";

        print $fh "server_address=$st->{server_address}\n" if $st->{server_address};
        print $fh "nsca_chroot=$st->{chroot}\n" if $st->{chroot};

        if ($fh->close()) {
            CAF::Service->new(["nsca"], log => $self)->restart();
        };
    }

    # send_nsca config
    if ( $config->elementExists(SEND_PATH) ) {
        my $st = $config->getElement(SEND_PATH)->getTree;
        my $uid = (getpwnam ($st->{user} || 'nagios'))[2];
        my $gid = (getpwnam ($st->{group} || 'nagios'))[3];
        my $fh = CAF::FileWriter->new(DAEMON_CFG,
                                      owner => $uid,
                                      group => $gid,
                                      mode => 0640,
                                      log => $self);

        print $fh "# send_nsca.cfg\n",
            "password=$st->{password}\n",
            "encryption_method=$st->{encryption_method}\n";

    }

    return 1;
}
