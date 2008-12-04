# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

package NCM::Component::portmap;
#
# a few standard statements, mandatory for all components
#
use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use LC::Process qw(trun);

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  my $enabled = $config->getValue("/software/components/portmap/enabled");

  if (defined($enabled) || ($enabled == "true")){
     system("/sbin/chkconfig --add portmap");
  } else {
     system("/sbin/chkconfig --del portmap");
  }
}

1; # required for Perl modules
