# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::openvpn;

use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Property;
use NCM::Check;
use FileHandle;
use LC::Process qw (execute);
use LC::Exception qw (throw_error);
use EDG::WP4::CCM::Element qw(unescape);

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use constant SERVER_PATH => '/software/components/openvpn/server';

use constant CLIENT_PATH => '/software/components/openvpn/client';

sub Configure
{
    my ($self, $config) = @_;

    # server configuration
    if ( $config->elementExists(SERVER_PATH) ) {
      my $serverconf = $config->getElement(SERVER_PATH);
      while ( $serverconf->hasNextElement ) {
        my $st = $serverconf->getNextElement()->getTree;
        my $fh = FileHandle->new (&unescape($st->{"configfile"}), 'w');
        unless ($fh) {
            throw_error ("Couldn't open " . &unescape($st->{"configfile"}));
            return 0;
        }

        my $resource = $serverconf->getCurrentElement();
        while ($resource->hasNextElement()) {
          my $elmt = $resource->getNextElement();
          next if $elmt->getName() eq "configfile";

          if ( $elmt->getType() == 33 ) {
            $fh->print($elmt->getName()."\n") if $elmt->getValue();
          } elsif ( $elmt->getName() eq "push" ) {
            my @routes;
            while ( $elmt->hasNextElement() ) {
              push @routes, $elmt->getNextElement()->getValue();
            }
            foreach (@routes){
                $fh->print("push \"$_\"\n");
            }
          } else {
            $fh->print($elmt->getName()." ".$elmt->getValue()."\n");
          }
        }


        chmod (0644, &unescape($st->{"configfile"}));
        execute (["/etc/init.d/openvpn", "restart"]);
      }
    }

    # client config
    if ( $config->elementExists(CLIENT_PATH) ) {
      my $clientconf = $config->getElement(CLIENT_PATH);
      while ( $clientconf->hasNextElement ) {
        my $st = $clientconf->getNextElement()->getTree;
        my $fh = FileHandle->new (&unescape($st->{"configfile"}), 'w');
        unless ($fh) {
            throw_error ("Couldn't open " . &unescape($st->{"configfile"}));
            return 0;
        }

        my $resource = $clientconf->getCurrentElement();
        while ($resource->hasNextElement()) {
          my $elmt = $resource->getNextElement();
          next if $elmt->getName() eq "configfile";

          if ( $elmt->getType() == 33 ) {
            $fh->print($elmt->getName()."\n") if $elmt->getValue();
          } elsif ( $elmt->getName() eq "remote" ) {
            my @servers;
            while ( $elmt->hasNextElement() ) {
              push @servers, $elmt->getNextElement()->getValue();
            }
            foreach (@servers) {
                $fh->print("remote $_\n");
            }
          } else {
            $fh->print($elmt->getName()." ".$elmt->getValue()."\n");
          }
        }


        chmod (0644, &unescape($st->{"configfile"}));
        execute (["/etc/init.d/openvpn", "restart"]);
      }
    }

    return 1;
}
