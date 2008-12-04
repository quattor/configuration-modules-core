# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

package NCM::Component::runlevel;

#
# a few standard statements, mandatory for all components
#

use strict;
use LC::Check;
use NCM::Check;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;


##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  my ($inittab)="/etc/inittab";
  my $path = "/software/components/runlevel/initdefault";
  unless ($config->elementExists("$path")){
    $self->error("Cannot determine initdefault runlevel from $path");
    return;
  }
  my $runlevel = $config->getValue("$path");

  if( ! -e $inittab){
    $self->error("No $inittab file found.");
    return; 
  }
  my $changes=0;

     $changes+=NCM::Check::lines($inittab,
                 linere => "id:.*:initdefault:",
                 goodre => "id:$runlevel:initdefault:",
                 good   => "id:$runlevel:initdefault:" );
  

  return;
}

##########################################################################
sub Unconfigure {
##########################################################################
  my ($self,$config)=@_;

  $self->info("Unconfiguring runlevel: doing nothing");

  return;
}


1; #required for Perl modules
