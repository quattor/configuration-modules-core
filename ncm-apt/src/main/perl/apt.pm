# ${license-info}
# ${developer-info}
# ${author-info}

#
# @COM@ - APT NCM component.
#
# Managed files:
#   /etc/apt/*
#   /etc/cron.d/apt.cron
#
################################################################################

package NCM::Component::apt;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use EDG::WP4::CCM::Element;


local(*DTA);


##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;

    }
    return 1;
}

1;      # Required for PERL modules
