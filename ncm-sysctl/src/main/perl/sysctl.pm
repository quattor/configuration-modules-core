# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# sysctl component
#
# generates the sysctl configuration file, /etc/sysctl.conf
#
#
# For license conditions see http://www.eu-datagrid.org/license.html
#
#######################################################################

package NCM::Component::sysctl;
#
# a few standard statements, mandatory for all components
#
use strict;
use NCM::Component;
our @ISA = qw(NCM::Component);
use LC::Exception qw(throw_error);
our $EC=LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element;

use NCM::Check;
use LC::Process qw(trun);

# For convenience
my $base = '/software/components/sysctl';


##########################################################################
sub Configure {
##########################################################################
    my ($self,$config)=@_;
    
    # Load config into a hash
    my $sysctl_config = $config->getElement($base)->getTree();
    my $variables = $sysctl_config->{variables};
    my $configFile = $sysctl_config->{confFile};
    my $changes;
    unless ( $configFile ) {
	$self->error('Sysctl configuration file not defined');
    }

    unless ($configFile =~ m{^(/.+)$}) {
	throw_error("Invalid configuration file in the profile: $configFile");
	return();
    }
    $configFile = $1;
    my $sysctl_exe = $sysctl_config->{command};
    unless ( $sysctl_exe ) {
	$self->error('Sysctl command not defined');
    }

    unless ($sysctl_exe =~ m{^(/\S+)$}) {
	throw_error("Invalid sysctl command on the profile: $sysctl_exe");
	return();
    }

    $sysctl_exe = $1;

    unless (-x $sysctl_exe) {
	$self->error ("$sysctl_exe not found");
	return;
    }

    unless (-e $configFile && -w $configFile) {
	$self->warn("Sysctl configuration file does not exist ",
		    "or is not writable ($configFile)");
	return;
    }

    foreach my $key (sort(keys(%$variables))) {
	my $value = $variables->{$key};
	my $st = NCM::Check::lines($configFile,
				   backup => '.old',
				   linere => '#?\s*'.$key.'\s*=.*',
				   goodre => '\s*'.$key.'\s*=\s*'.$value,
				   good => "$key = $value",
				   add => 'last'
				  );
	if ($st < 0) {
	    $self->error("Failed to update sysctl $key (value=$value)");
	} else {
	    $changes += $st;
	}
    }

    #
    # execute /sbin/sysctl -p if any change made to sysctl configuration file
    #
    if ( $changes ) {
	unless (LC::Process::trun(300,"$sysctl_exe", "-p")) {
	    $self->error('Failed to load sysctl settings from $configFile');
	    return;
	}
    }
}



1; # required for Perl modules
