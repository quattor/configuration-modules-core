#${PMcomponent}

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;
use File::Copy;

sub Configure
{

    my ($self, $config) = @_;

    my $base = "/software/components/hostsaccess";
    my $date = localtime();

    # Pull out the configuration for "allowed" hosts.
    my $contents = "# Created by ncm-hostsaccess on $date\n";
    if ($config->elementExists("$base/allow")) {
        my $allowed = $config->getElement("$base/allow");

        # Loop through all of the entries creating the necessary content.
        while ($allowed->hasNextElement()) {
            my %entry = $allowed->getNextElement()->getHash();
            my $daemon = $entry{'daemon'}->getValue();
            my $host = $entry{'host'}->getValue();
            $contents .= "$daemon : $host\n";
        }
    }

    # Write the /etc/hosts.allow file.
    my $fname = "/etc/hosts.allow";
    open CONF,">$fname";
    print CONF $contents;
    close CONF;

    # Pull out the configuration for "denied" hosts.
    $contents = "# Created by ncm-hostsaccess on $date\n";
    if ($config->elementExists("$base/deny")) {
        my $denied = $config->getElement("$base/deny");

        # Loop through all of the entries creating the necessary content.
        while ($denied->hasNextElement()) {
            my %entry = $denied->getNextElement()->getHash();
            my $daemon = $entry{'daemon'}->getValue();
            my $host = $entry{'host'}->getValue();
            $contents .= "$daemon : $host\n";
        }
    }

    # Write the /etc/hosts.allow file.
    $fname = "/etc/hosts.deny";
    open CONF,">$fname";
    print CONF $contents;
    close CONF;

    return 1;
}

1;      # Required for PERL modules
