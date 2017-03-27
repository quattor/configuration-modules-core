#${PMcomponent}

=head1 NAME

The I<cdp> component manages the configuration file
C<< /etc/cdp-listend.conf. >>

=head1 DESCRIPTION

The I<cdp> component manages the configuration file for the
cdp-listend daemon.

=head1 EXAMPLES

    include 'components/cdp/config';
    prefix "/software/components/cdp";
    "fetch" = "/usr/sbin/ccm-fetch";
    "fetch_smear" = 30;

=cut

use parent qw(NCM::Component);

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

use CAF::FileWriter;
use CAF::Service;

use File::Path;
use File::Basename;

sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getTree($self->prefix());

    my $fh = CAF::FileWriter->new($t->{configFile}, log => $self);

    delete($t->{active});
    delete($t->{dispatch});
    delete($t->{dependencies});
    delete($t->{configFile});
    delete($t->{version});

    foreach my $k (sort keys %$t) {
        print $fh "$k = $t->{$k}\n";
    }

    if ($fh->close()) {
        my $srv = CAF::Service->new(['cdp-listend'], log => $self);
        $srv->restart();
    }

    return 1;
}

1;
