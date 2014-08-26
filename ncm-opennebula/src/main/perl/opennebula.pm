# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::opennebula;

use strict;
use NCM::Component;
use base qw(NCM::Component);
use vars qw(@ISA $EC);
use LC::Exception;

our $EC=LC::Exception::Context->new->will_store_all;

sub Configure
{
    my ($self, $config) = @_;

    # Define paths for convenience.
    my $t = $config->getElement("/software/components/opennebula")->getTree();

    return 1;
}

1;
