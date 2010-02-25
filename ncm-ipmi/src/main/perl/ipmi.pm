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

use EDG::WP4::CCM::Element;

use LC::Check;

use Encode qw(encode_utf8);

local(*DTA);


use EDG::WP4::CCM::Element;

##########################################################################
sub Configure($$) {
##########################################################################
  my ($self,$config)=@_;
  my $base     = "/software/components/ipmi/";
  my $ipmi_exec = "/usr/bin/ipmitool";

  my $ipmi_config = $config->getElement($base)->getTree();

  my $users   = $ipmi_config->{users};
  my $channel = $ipmi_config->{channel};
  my $net_interface = $ipmi_config->{net_interface};

  system("chkconfig ipmi on");
  system("service ipmi restart");

  for my $user (@{$users}) {
	my $userid = $user->{userid};
        my $login  = $user->{login};
	my $passwd = $user->{password};
	my $priv   = $user->{priv};

	system ($ipmi_exec." user set name ".$userid." ".$login);
	system ($ipmi_exec." user set password ".$userid." ".$passwd);
#	system ($ipmi_exec." user priv ".$userid." ".$priv);
	
  }


  system ($ipmi_exec." mc reset cold");

  return; # return code is not checked.
}



sub ConfigureNetwork {
	return;
}

1; # Perl module requirement.
