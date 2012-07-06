# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::pakiti - NCM pakiti configuration component
#
# configures /etc/pakiti/pakiti-client.conf
#
################################################################################

package NCM::Component::pakiti;
#
# a few standard statements, mandatory for all components
#
use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
#use LC::Process qw(trun);

##########################################################################
sub Configure {
##########################################################################

  my ($self,$config)=@_;
  my $pakiti_conf = "/etc/pakiti/pakiti-client.conf";

  my $pakiti_server_url;
  my $pakiti_admin;
  my $pakiti_method;

  if ($config->elementExists("/software/components/pakiti/server_url")){
    $pakiti_server_url = $config->getValue("/software/components/pakiti/server_url");
  }

  if ($config->elementExists("/software/components/pakiti/admin")){
    $pakiti_admin = $config->getValue("/software/components/pakiti/admin");
  }

  if ($config->elementExists("/software/components/pakiti/method")){
    $pakiti_method = $config->getValue("/software/components/pakiti/method");
  }

  NCM::Check::lines($pakiti_conf,
                    linere => "server_url =.*",
                    goodre => "server_url = $pakiti_server_url",
                    good   => "server_url = $pakiti_server_url");

  NCM::Check::lines($pakiti_conf,
                    linere => "admin =.*",
                    goodre => "admin = $pakiti_admin",
                    good   => "admin = $pakiti_admin");

  NCM::Check::lines($pakiti_conf,
                    linere => "method =.*",
                    goodre => "method = $pakiti_method",
                    good   => "method = $pakiti_method");

}

1; # required for Perl modules

