#${PMcomponent}

#
# Implementation of ncm-pnp4nagios
# Author: Laura del Cano Novales <laura.delcano@uam.es>
#

use Socket;
use CAF::Process;
use CAF::FileWriter;
use LC::Exception qw (throw_error);
use File::Path;

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all();

use constant PNP4NAGIOS_FILES => {
    nagios => '/etc/pnp4nagios/nagios.cfg',
    php => '/etc/pnp4nagios/config.php',
    npcd => '/etc/pnp4nagios/npcd.cfg',
    perfdata => '/etc/pnp4nagios/process_perfdata.cfg',
};

use constant BASEPATH => "/software/components/pnp4nagios/";

my $PNP4NAGIOS_USR;
my $PNP4NAGIOS_GRP;

# thank you npcd for requiring a correctly ordened config file
use constant NPCD_OPTIONS => qw(user group log_type log_file max_logfile_size log_level
						perfdata_spool_dir perfdata_file_run_cmd perfdata_file_run_cmd_args identify_npcd npcd_max_threads
 						sleep_time load_threshold pid_file perfdata_file perfdata_spool_filename perfdata_file_processing_interval);


# Prints all settings for nagios
sub print_nagios
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open (PNP4NAGIOS_FILES->{nagios},
				    owner => $PNP4NAGIOS_USR,
				    group => $PNP4NAGIOS_GRP,
				    log => $self,
				    mode => 0444);

    while (my ($opt, $val) = each (%$t)) {
		if (ref ($val)) {
			print $fh "$opt=", join (" ", @$val), "\n";
		} else {
		    print $fh "$opt=$val\n";
		}
    }
    return $fh;
}

# Prints all settings for npcd
sub print_npcd
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open (PNP4NAGIOS_FILES->{npcd},
				    owner => $PNP4NAGIOS_USR,
				    group => $PNP4NAGIOS_GRP,
				    log => $self,
				    mode => 0444);

	foreach my $something (NPCD_OPTIONS) {

		my $val = $t -> {$something};
		print $fh "$something = $val\n";

	}
	print $fh "\n";

    return $fh;
}

# Prints all settings for perfdata
sub print_perfdata
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open (PNP4NAGIOS_FILES->{perfdata},
				    owner => $PNP4NAGIOS_USR,
				    group => $PNP4NAGIOS_GRP,
				    log => $self,
				    mode => 0444);

    while (my ($opt, $val) = each (%$t)) {
    	if ( $opt eq "use_rrds"){
    		print $fh "USE_RRDs = $val\n";
    	} else {
	    	print $fh uc($opt) . " = $val\n";
	    }
    }
    return $fh;
}

# Prints all settings for php
sub print_php
{
    my ($self, $t) = @_;

    my $fh = CAF::FileWriter->open (PNP4NAGIOS_FILES->{php},
				    owner => $PNP4NAGIOS_USR,
				    group => $PNP4NAGIOS_GRP,
				    log => $self,
				    mode => 0444);

	print $fh "<\?php\n";

    while (my ($opt, $val) = each (%$t)) {
    	#Special boolean :s
    	if ( $opt eq "auth_enabled"){
    		if ( $val ) {
    			print $fh "\$conf['$opt']=TRUE;\n";
    		} else {
    			print $fh "\$conf['$opt']=FALSE;\n";
    		}

    	} else {
    		#write views
    		if ( $opt eq "views"){
            	foreach my $it (@$val) {
                	print $fh "\$views[]= array('title' => '$it->{title}', 'start' => ($it->{start}) );\n";
                }

    		} else {
	            #write template_dirs
                if ( $opt eq "template_dirs"){
     	           foreach my  $templ_dir  (@$val) {
            	       print $fh "\$conf['$opt'][]=\"$templ_dir\";\n";
        	       }

    			} else {

    				if ( $opt eq "rrd_daemon_opts"){
    					print $fh "\$conf['".uc($opt)."']=\"$val\";\n";

    				} else {
	    				#Don't quote a number
						if ( $val =~ /^[+-]?\d+$/ ) {
							print $fh "\$conf['$opt']=$val;\n";

						#Write the rest
						} else {
		    				print $fh "\$conf['$opt']=\"$val\";\n";
						}
					}
				}
			}
		}
    }

    print $fh "?\>\n";

    return $fh;
}

# Restarts the npcd daemon if needed.
sub restart_npcd
{
    my $self = shift;

    my $cmd = CAF::Process->new([qw(service npcd restart)], log => $self);

    $cmd->run();
    return $cmd;
}

# Configure method. Writes all the configuration files and starts or
# reloads the npcd service
sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement(BASEPATH)->getTree();

	$PNP4NAGIOS_USR = (getpwnam ($t->{npcd}->{user}))[2];
	$PNP4NAGIOS_GRP = (getpwnam ($t->{npcd}->{user}))[3];

    $self->print_nagios ($t->{nagios});
    $self->print_php ($t->{php});
    $self->print_perfdata ($t->{perfdata});
	$self->print_npcd ($t->{npcd});

    $self->restart_npcd();

    return !$?;
}
1;
