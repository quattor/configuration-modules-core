# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::ipmi;
#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use File::Copy;
use CAF::Process;
use EDG::WP4::CCM::Element;

use LC::Check;

use Encode qw(encode_utf8);

local(*DTA);

use constant IPMI_EXEC => "/usr/bin/ipmitool";
use constant BASEPATH => "/software/components/ipmi/";


use EDG::WP4::CCM::Element;

##########################################################################
sub Configure($$) {
##########################################################################
  my ($self,$config)=@_;

  my $ipmi_config = $config->getElement(BASEPATH)->getTree();

  my $users   = $ipmi_config->{users};
  my $channel = $ipmi_config->{channel};
  my $net_interface = $ipmi_config->{net_interface};

  CAF::Process->new([qw(chkconfig ipmi on)], log => $self)->run();
  CAF::Process->new([qw(service ipmi restart)], log => $self)->run();

  for my $user (@{$users}) {
        my $userid = $user->{userid};
        my $login  = $user->{login};
        my $passwd = $user->{password};
        my $priv   = $user->{priv};

        CAF::Process->new([IPMI_EXEC, qw(user set name), $userid, $login],
                          log => $self)->run();
        CAF::Process->new([IPMI_EXEC, qw(user set password), $userid, $passwd],
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
