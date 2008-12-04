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

  #
  # Set options for SSH daemon
  #
  my $valPath = '/software/components/ssh/daemon/options';
  my $perms;

  if ($config->elementExists($valPath)) {
    my $re = $config->getElement($valPath);

    # preserve permissions
    if ( $perms=(stat('/etc/ssh/sshd_config'))[2] ) {

      my $cnt = 0;
      while($re->hasNextElement()) {

        my $ce = $re->getNextElement();
        my $optname = $ce->getName(); 
        my $val = $ce->getValue();

        unless($val) { 
          $self->error("no value found for option $optname");
          next;
        }

        $cnt += NCM::Check::lines('/etc/ssh/sshd_config',
			backup => '.old',
			linere => '(?i)^\W*'.$optname.'\s+\S+',
			goodre => '\s*'.$optname.'\s+'.$val,
			good   => "$optname $val",
			keep   => 'first',
			add    => 'last'
			);
      }	

      #reload if changed the conf-file
      if($cnt) {
        chmod $perms,'/etc/ssh/sshd_config' or $self->warn("cannot reset permissions on /etc/ssh/sshd_config: $!");
        LC::Process::run('/sbin/service sshd reload') or $self->warn('command "/sbin/service sshd reload" failed');
      }

    } else {
      $self->warn("cannot stat /etc/ssh/sshd_config: $!");
    }
  }

  ## options that should be commented
  $valPath = '/software/components/ssh/daemon/comment_options';

  if ($config->elementExists($valPath)) {
    my $re = $config->getElement($valPath);

    # preserve permissions
    if ( $perms=(stat('/etc/ssh/sshd_config'))[2] ) {

      my $cnt = 0;
      while($re->hasNextElement()) {

        my $ce = $re->getNextElement();
        my $optname = $ce->getName(); 
        my $val = $ce->getValue();

        unless($val) { 
          $self->error("no value found for option $optname");
          next;
        }

        $cnt += NCM::Check::lines('/etc/ssh/sshd_config',
            backup => '.old',
            linere => '(?i)^\W*'.$optname.'\s+\S+',
            goodre => '\s*#'.$optname.'\s+\S+',
            good   => "#$optname $val",
            keep   => 'first',
            add    => 'last'
            );
      } 

      #reload if changed the conf-file
      if($cnt) {
        chmod $perms,'/etc/ssh/sshd_config' or $self->warn("cannot reset permissions on /etc/ssh/sshd_config: $!");
        LC::Process::run('/sbin/service sshd reload') or $self->warn('command "/sbin/service sshd reload" failed');
      }

    } else {
      $self->warn("cannot stat /etc/ssh/sshd_config: $!");
    }
  }


  #
  # Set options for SSH client
  #
  $valPath = '/software/components/ssh/client/options';

  if ($config->elementExists($valPath)) {
    my $re = $config->getElement($valPath);

    # preserve permissions
    if ( $perms=(stat('/etc/ssh/ssh_config'))[2] ) {

      my $cnt = 0;
      while($re->hasNextElement()) {

        my $ce = $re->getNextElement();
        my $optname = $ce->getName(); 
        my $val = $ce->getValue();

        unless($val) { 
          $self->error("no value found for option $optname");
          next;
        }

        $cnt += NCM::Check::lines('/etc/ssh/ssh_config',
			backup => '.old',
			linere => '(?i)^\W*'.$optname.'\s+\S+',
			goodre => '\s*'.$optname.'\s+'.$val,
			good   => "$optname $val",
			keep   => 'first',
			add    => 'last'
			);
      }	

      if($cnt) {
        chmod $perms,'/etc/ssh/ssh_config' or $self->warn("cannot reset permissions on /etc/ssh/ssh_config: $!");
      }

    } else {
      $self->warn("cannot stat /etc/ssh/ssh_config: $!");
    }
  }

  return;
}

##########################################################################
sub Unconfigure {
##########################################################################
}


1; #required for Perl modules
