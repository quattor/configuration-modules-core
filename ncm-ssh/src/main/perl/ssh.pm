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

use CAF::Process;
use CAF::FileEditor;
use constant SSHD_CONFIG => "/etc/ssh/sshd_config";
use constant SSH_CONFIG => "/etc/ssh/ssh_config";

sub Configure
{
    my ($self,$config)=@_;

    # Retrieve configuration and do some initializations
    # Define paths for convenience.
    my $base = "/software/components/ssh";
    my $ssh_config = $config->getElement($base)->getTree();

    #
    # Process options for SSH daemon and client: processing is almost
    # identical for both.  Main difference is that the daemon must be
    # restarted if changes were made to the configuration file.  This
    # is made of 2 set of options : the options that must be defined
    # with their value and the options that must be commented out.
    #

    foreach my $component (qw(daemon client)) {
	my $component_name;
	my $ssh_config_file;
	if ( $component eq 'daemon' ) {
	    $component_name = 'sshd';
	    $ssh_config_file = SSHD_CONFIG;
	} else {
	    $component_name = 'ssh client';
	    $ssh_config_file = SSH_CONFIG;
	}
	if ( $ssh_config->{$component} ) {
	    $self->info("Checking $component_name configuration...");

	    # Ensure the daemon config file alreay exists.
	    # This component will edit it.
	    if ( my $perms=(stat($ssh_config_file))[2] ) {
		my $cnt = 0;

		# Options defined take precedence over commented out
		foreach my $option_set (qw(comment_options options)) {
		    if ( $ssh_config->{$component}->{$option_set} ) {
			$self->debug(1,"Processing $component $option_set");
			my $ssh_component_config = $ssh_config->{$component}->{$option_set};
			while (my ($option, $val) = each(%$ssh_component_config)) {
			    my $comment;
			    if ( $option_set eq 'comment_options' ) {
				$comment = '#';
			    } else {
				$comment = '';
			    }

			    my $escaped_val = $val;
			    $escaped_val =~ s{([?{}.()\[\]])}{\\$1}g;
			    my $result = NCM::Check::lines($ssh_config_file,
							   backup => '.old',
							   linere => '(?i)^\W*'.$option.'\s+\S+',
							   goodre => '\s*'.$comment.'\s*'.$option.'\s+'.$escaped_val,
							   good   => $comment."$option $val",
							   keep   => 'first',
							   add    => 'last'
				);
			    if ( $result < 0 ) {
				$self->error("Error during update of $ssh_config_file (option=$option)");
			    } else {
				$cnt += $result;
			    }
			}
		    }
		}

		#restart if changed the conf-file
		if($cnt) {
		    chmod $perms,$ssh_config_file or $self->warn("cannot reset permissions on $ssh_config_file ($!)");
		    if ( $component eq 'daemon' ) {
			$self->info("Restarting $component...");
			CAF::Process->new([qw(/sbin/service sshd condrestart)],
					  log => $self)->run();
			$self->error("Failed to reload $component") if $?;
		    }
		}

	    } else {
		$self->error("$component configuration missing ($ssh_config_file). Check ssh installation.");
	    }
	}
    }

    return 1;
}

##########################################################################
sub Unconfigure {
##########################################################################
}


1; #required for Perl modules
