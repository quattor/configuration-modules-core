# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::mailaliases - NCM mailaliases configuration component
#
# configures /etc/aliases
#
################################################################################

package NCM::Component::mailaliases;
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
  my $mailaliases = "/etc/aliases";

  my $legacyrootmail;
  my %mailusers;

  if ($config->elementExists("/system/rootmail")){
    $legacyrootmail = $config->getValue("/system/rootmail");
    # $self->warn("/system/rootmail is obsolete, please use /software/components/mailaliases/*; check man ncm-mailaliases");
    push (@{$mailusers{"root"}},$legacyrootmail);
  }

  my $userpath="/software/components/mailaliases/user";
  my $user;
  my $username;

  if ($config->elementExists($userpath)){
    $user=$config->getElement($userpath);
    while($user->hasNextElement()){
      $username=$user->getNextElement()->getName();
      my $emailaddress;
      my $recipient=$config->getElement($userpath."/".$username."/recipients");
      if ($recipient->hasNextElement()){
        my @recipients=$recipient->getList();
        foreach my $recnr ( 0 .. $#recipients){
           push(@{$mailusers{$username}}, $recipients[$recnr]->getValue());
        }
      }
    }
  }

  my $changes=0;

  foreach $username (keys %mailusers){
    my $line=$username.":\t\t";
    $line.=join(',',@{$mailusers{$username}});

    $changes+=NCM::Check::lines($mailaliases,
        linere => "$username:.*",
        goodre => $line,
        good   => $line );
  }

  system("/usr/bin/newaliases") if ($changes > 0);
}

1; # required for Perl modules
