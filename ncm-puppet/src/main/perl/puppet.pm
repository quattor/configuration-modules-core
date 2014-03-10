# #
# Software subject to following license(s):
#   Apache 2 License (http://www.opensource.org/licenses/apache2.0)
#   Copyright (c) Responsible Organization
#

# #
# Current developer(s):
#   Charles Loomis <charles.loomis@cern.ch>
#

# #
# Author(s): Jane SMITH, Joe DOE
#



package NCM::Component::puppet;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC  = LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element qw(unescape);

use LC::File;
use CAF::Process;

use constant MODULE_INSTALL => 'puppet module upgrade %s %s||puppet module install %s %s';
use constant NODEFILES_PATH => '/etc/puppet/manifests';
use constant CONFIG_FILE => '/etc/puppet/puppet.conf';
use constant APPLY => 'puppet apply --detailed-exitcodes -v -l /var/log/puppet/log %s;test $? == 2;';

local (*DTA);

##########################################################################
sub Configure($$@) {
##########################################################################

  my ( $self, $config ) = @_;

  # Define path for convenience.
  my $base = "/software/components/puppet";

  # Retrieve component configuration
  my $confighash = $config->getElement($base)->getTree();

  # Update the config file
  $self->configfile($confighash) if(defined($confighash->{configfile}));
  
  # Install/Upgrade modules
  $self->install_modules($confighash) if(defined($confighash->{modules})); 

  # Prepare the node files
  $self->nodefiles($confighash);

  # Run puppet apply
  $self->apply($confighash);

  return 0;
}

sub apply {
    my $self=shift;
    my $confighash=shift;

    foreach my $file (sort keys %{$confighash->{nodefiles}}){

	$self->cmd_exec(sprintf(APPLY,NODEFILES_PATH."/".unescape($file)))
    }
}

sub configfile {
    my $self=shift;
    my $confighash=shift;
    
  LC::Check::file(
      CONFIG_FILE,
      contents => $confighash->{configfile},
      );

    return 0;
}

sub nodefiles {
    my $self=shift;
    my $confighash=shift;

    foreach my $file (sort keys %{$confighash->{nodefiles}}){
	if($confighash->{nodefiles}->{$file}->{contents}){
	    my $path=NODEFILES_PATH."/".unescape($file);
	    LC::Check::file(
		$path,
		contents => $confighash->{nodefiles}->{$file}->{contents},
		);
	}
	
    }
    return 0;
}

sub install_modules {
    my $self=shift;
    my $confighash=shift;

    foreach my $mod (sort keys %{$confighash->{modules}}){
	my $module=unescape($mod);
	my $version='';
	if(defined($confighash->{modules}->{$mod}->{version})){
	    $version="--version=".$confighash->{modules}->{$mod}->{version};
	}
	my $cl = sprintf(MODULE_INSTALL,$module,$version,$module,$version);
	$self->cmd_exec($cl);
    }
    return 0;
}

sub cmd_exec {
    my $self=shift;
    my $cl=shift;

    my $cmd_output;

    my $cmd = CAF::Process->new([$cl], log => $self,
                                shell => 1,
                                stdout => \$cmd_output,
				  stderr => "stdout");
    $cmd->execute();

    if ( $? ) {
	$self->error("Command failed. Command output: $cmd_output\n");
    } else {
	$self->debug(1,"Command output: $cmd_output\n");
    }

    return $cmd_output;

}

1;    # Required for PERL modules
