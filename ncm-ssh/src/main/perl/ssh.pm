# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# ssh component
#
# NCM SSH configuration component
#
#
# For license conditions see http://www.eu-datagrid.org/license.html
#
#######################################################################

package NCM::Component::ssh;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use LC::Process qw(run);
use LC::File qw(copy file_contents);

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  # Retrieve configuration and do some initializations
  # Define paths for convenience. 
  my $base = "/software/components/ssh";
  my $ssh_config = $config->getElement($base)->getTree();
  
  #
  # Process options for SSH daemon and client: processing is almost identical for both.
  # Main difference is that the daemon must be restarted if changes were made to the configuration file.
  # This is made of 2 set of options : the options that must be defined with their value
  # and the options that must be commented out.
  #

  for my $component ('daemon', 'client') {
    my $component_name;
    my $ssh_config_file;
    if ( $component eq 'daemon' ) {
      $component_name = 'sshd';
      $ssh_config_file = '/etc/ssh/sshd_config';
    } else {
      $component_name = 'ssh client';
      $ssh_config_file = '/etc/ssh/ssh_config';
    }
    if ( $ssh_config->{$component} ) {
      $self->info("Checking $component_name configuration...");
      
      # Ensure the daemon config file alreay exists.
      # This component will edit it.
      if ( my $perms=(stat($ssh_config_file))[2] ) {
        my $cnt = 0;
  
        # Options defined take precedence over commented out
        for my $option_set ('comment_options', 'options') {
          if ( $ssh_config->{$component}->{$option_set} ) {
            $self->debug(1,"Processing $component $option_set");
            my $ssh_component_config = $ssh_config->{$component}->{$option_set};
            for my $option (@{$ssh_config_daemon}) {
              my $val = $ssh_component_config->{$option};
              unless ( defined($val) ) { 
                $self->error("no value found for option $optname");
                next;
              }
    
              my $comment = '';
              if ( $option_set eq 'comment_options' ) {
                $comment = '#';
              }
              my $result = NCM::Check::lines($shh_config_file,
                                             backup => '.old',
                                             linere => '(?i)^\W*'.$optname.'\s+\S+',
                                             goodre => '\s*'.$comment.'\s*'.$optname.'\s+'.$val,
                                             good   => $comment."$optname $val",
                                             keep   => 'first',
                                             add    => 'last'
                                            );
              if ( $result < 0 ) {
                $self->error("Error during update of $shh_config_file (option=$option)");
              } else {
                $cnt += $result;
              }
            }
          }
        }

        #reload if changed the conf-file
        if($cnt) {
          chmod $perms,$shh_config_file or $self->warn("cannot reset permissions on $shh_config_file ($!)");
          if ( $component eq 'daemon' ) {
            $self->info("Restarting $component...")
            LC::Process::run('/sbin/service sshd reload') or $self->warn('command "/sbin/service sshd reload" failed');            
          }
        }
  
      } else {
        $self->error("$component configuration missing ($shh_config_file). Check ssh installation.");
      }
    }
  }

  return;
}

##########################################################################
sub Unconfigure {
##########################################################################
}


1; #required for Perl modules
