# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::tftpd - NCM tftpd configuration component
#
################################################################################

package NCM::Component::tftpd;

#
# a few standard statements, mandatory for all components
#

use strict;
use LC::Check;
use NCM::Check;
use NCM::Component;
use NCM::Template;

use vars qw(@ISA $EC);
@ISA = qw(NCM::Component NCM::Template);
$EC=LC::Exception::Context->new->will_store_all;

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  my $tftpd = "/etc/xinetd.d/tftp";

  if( ! -e $tftpd){
    $self->error("No $tftpd file found.");
    return;
  }

  my $changes=0;

  if ( $config->elementExists("/software/components/tftpd/disable") ){
	my $disable = $config->getValue("/software/components/tftpd/disable");
	print "disable: $disable\n";
 	$changes+=NCM::Check::lines($tftpd,
                  linere => "^\\s*disable\\s*=\\s*.*",
                  goodre => "^\\s*disable\\s*=\\s*$disable",
                  good   => "\tdisable\t\t\t= $disable" );
  }
  if ( $config->elementExists("/software/components/tftpd/wait") ){
	my $wait = $config->getValue("/software/components/tftpd/wait");
 	$changes+=NCM::Check::lines($tftpd,
                  linere => "\\s*wait\\s*=\\s*.*",
                  goodre => "\\s*wait\\s*=\\s*$wait",
                  good   => "\twait\t\t\t= $wait" );
  }
  if ( $config->elementExists("/software/components/tftpd/user") ){
	my $user = $config->getValue("/software/components/tftpd/user");
 	$changes+=NCM::Check::lines($tftpd,
                  linere => "\\s*user\\s*=\\s*.*",
                  goodre => "\\s*user\\s*=\\s*$user",
                  good   => "\tuser\t\t\t= $user" );
  }
  if ( $config->elementExists("/software/components/tftpd/server") ){
	my $server = $config->getValue("/software/components/tftpd/server");
 	$changes+=NCM::Check::lines($tftpd,
                  linere => "\\s*server\\s*=\\s*.*",
                  goodre => "\\s*server\\s*=\\s*$server",
                  good   => "\tserver\t\t\t= $server" );
  }
  if ( $config->elementExists("/software/components/tftpd/server_args") ){
	my $server_args = $config->getValue("/software/components/tftpd/server_args");
 	$changes+=NCM::Check::lines($tftpd,
                  linere => "\\s*server_args\\s*=\\s*.*",
                  goodre => "\\s*server_args\\s*=\\s*$server_args",
                  good   => "\tserver_args\t\t= $server_args" );
  }
  system ("/sbin/service","xinetd", "reload" ) if $changes;

}

##########################################################################
sub Unconfigure {
##########################################################################
  my ($self,$config)=@_;

  $self->info("Unconfiguring tftpd. Doing nothing.");

  return;
}


1; #required for Perl modules
