#${PMcomponent}

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use File::Copy;
use CAF::Process;

use constant IPMI_EXEC => "/usr/bin/ipmitool";
use constant BASEPATH => "/software/components/ipmi/";

sub Configure
{

  my ($self, $config) = @_;

  my $ipmi_config = $config->getElement(BASEPATH)->getTree();

  my $users   = $ipmi_config->{users};
  my $channel = $ipmi_config->{channel};

  CAF::Process->new([qw(chkconfig ipmi on)], log => $self)->run();
  CAF::Process->new([qw(service ipmi restart)], log => $self)->run();
  #Ensure IPMI over LAN is enabled
  CAF::Process->new([IPMI_EXEC, qw(lan set), $channel, qw(access on)], log => $self)->run();
  #Set user authentication to use MD5 security (about as good as it gets)
  CAF::Process->new([IPMI_EXEC, qw(lan set), $channel, qw(auth USER MD5)], log => $self)->run();

  for my $user (@{$users}) {
      my $userid = $user->{userid};
      my $login  = $user->{login};
      my $passwd = $user->{password};
      my $priv   = $user->{priv};

      #Create and enable user account
      CAF::Process->new([IPMI_EXEC, qw(user set name), $userid, $login],
                        log => $self)->run();
      CAF::Process->new([IPMI_EXEC, qw(user set password), $userid, $passwd],
                        log => $self)->run();
      CAF::Process->new([IPMI_EXEC, qw(user set priv), $userid, sprintf("0x%X", $priv)],
                        log => $self)->run();
      CAF::Process->new([IPMI_EXEC, qw(user enable), $userid],
                        log => $self)->run();
      #Set remote access via LAN
      CAF::Process->new([IPMI_EXEC, qw(channel setaccess), $channel, $userid, qw(link=on ipmi=on callin=on)],
                        log => $self)->run();
  }

  CAF::Process->new([IPMI_EXEC, qw(mc reset cold)],
                    log => $self)->run();

  return; # return code is not checked.
}



sub ConfigureNetwork {
    return;
}

1; # Perl module requirement.
