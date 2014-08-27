# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::cdp;

use strict;
use base 'NCM::Component';
our $EC=LC::Exception::Context->new->will_store_all;
use CAF::FileWriter;
use CAF::Service;

use File::Path;
use File::Basename;

local(*DTA);

use constant BASE => "/software/components/cdp";


sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement(BASE)->getTree();

    my $fh = CAF::FileWriter->new($t->{configFile}, log => $self);

    delete($t->{active});
    delete($t->{dispatch});
    delete($t->{dependencies});
    delete($t->{configFile});
    delete($t->{version});

    foreach my $k (sort keys %$t) {
        print $fh "$k = $t->{$k}\n";
    }

    if($fh->close()) {
        my $srv = CAF::Service->new(['cdp-listend'], log => $self, %opts);
        $srv->restart();
    }

    return 1;
}

1;      # Required for PERL modules
