# ${license-info}
# ${developer-info}
# ${author-info}

# File: pnp4nagios.pm
# Implementation of ncm-pnp4nagios
# Author: Laura del Cano Novales <laura.delcano@uam.es>
# Version: 2.0.0 : 03/04/09 14:39
#  ** Generated file : do not edit **
#
# Note: all methods in this component are called in a
# $self->$method ($config) way, unless explicitly stated.

package NCM::Component::pnp4nagios;

#
# a few standard statements, mandatory for all components
#

use strict;
use warnings;
use NCM::Component;
our @ISA = qw(NCM::Component);
our $EC=LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element;

use CAF::FileWriter;
use CAF::Process;

use constant PATH       => '/software/components/pnp4nagios/';
use constant NPCD_CONFIG_FILE => '/etc/pnp4nagios/npcd.cfg';
use constant PHP_CONFIG_FILE => '/etc/pnp4nagios/config.php';
use constant PAGES_DIR_DEF => '/etc/pnp4nagios/pages';
use constant TEMPLATES_DIR_DEF => '/usr/share/nagios/html/pnp4nagios/templates';
use constant NPCD_PIDFILE => '/var/run/npcd.pid';
use constant NPCD_RELOAD => qw (/sbin/service npcd reload);
use constant NPCD_START => qw (/sbin/service npcd start);

my $pages_dir = PAGES_DIR_DEF;


# Prints npcd conf file.
# Fields need to be in order and last line should be empty
sub print_npcd_file
{
        my ($self, $fh, $cfg) = @_;
        
        use constant NPCD_FIELDS => qw(user group log_type log_file max_logfile_size 
        	log_level perfdata_spool_dir perfdata_file_run_cmd perfdata_file_run_cmd_args
        	npcd_max_threads sleep_time use_load_threshold load_threshold pid_file);
        
        foreach my $item (NPCD_FIELDS) {
    		print $fh "$item = $cfg->{$item}\n" if (exists($cfg->{$item}));
		} 

		print $fh "\n";
        return;

}

# Prints php conf file.
sub print_php_file
{
        my ($self, $fh, $cfg, $elem) = @_;
        
        my $elem_conf=$elem->getConfiguration();
        
        print $fh "<?php\n";
        while (my ($k, $v) = each %{$cfg->{'conf'}}) {
        	my $elem_k = $elem_conf->getElement(PATH . "php/conf/$k/");
            if ($elem_k->isType(EDG::WP4::CCM::Element::STRING)) {
            	print $fh "\$conf[\'$k\'] = \"$v\";\n";
            } else {
                print $fh "\$conf[\'$k\'] = $v;\n";
            };
        	
        	# If option = page_dir save it on the global variable
        	if ($k eq 'page_dir') {
        		$pages_dir = $v;
        	}
        }

        foreach my $view (@{$cfg->{'views'}}) {
			print $fh "\$views[$view->{'index'}][\"title\"] = \"$view->{'title'}\";\n";
			print $fh "\$views[$view->{'index'}][\"start\"] = $view->{'start'};\n";
        }
        print $fh "?>\n";        
        return;
}

# Prints page file.
sub print_page_file
{
        my ($self, $fh, $cfg) = @_;
        
        # Print page definition
        print $fh "define page {\n";     
        while (my ($k, $v) = each %{$cfg->{'page_cfg'}}) {
        	print $fh " $k $v\n";
        }
        print $fh "}\n";
        
        # Print graph definition
        foreach my $graph (@{$cfg->{'graphs'}}) {
        	print $fh "define graph {\n";     
        	while (my ($kg, $vg) = each %{$graph}) {
        		print $fh " $kg $vg\n";
        	}
        	print $fh "}\n";        
        }
        return;

}

# Prints template file.
sub print_template_file
{
        my ($self, $fh, $cfg) = @_;
        my $count = 0;
        
        print $fh "<?php\n";
                
        # For each dataset print configuration
        foreach my $dataset (@{$cfg->{'datasets'}}) {
        	# Print option
        	print $fh "\$opt[$dataset->{'index'}] = \"$dataset->{'opt'}\";\n";
        	
        	# Print definitions
        	foreach my $def (@{$dataset->{'defs'}}) {
        		print $fh "if ($def->{'cond'}) {\n" if (exists($def->{'cond'}));
        		print $fh "\$def[$dataset->{'index'}] ";
        		print $fh "." unless ($count == 0); 
        		print $fh "= \"$def->{'def'}\";\n";
        		print $fh "}\n" if (exists($def->{'cond'}));
        		$count++;
        	}       
        }
        
        print $fh "?>\n";   
        return;

}
##########################################################################
# Reloads npcd daemon, if it is running.
##########################################################################
sub npcd_reload
{
	my $proc;
    if (-f NPCD_PIDFILE) {
    	$proc = CAF::Process->new ([NPCD_RELOAD]);
    } else {
        $proc = CAF::Process->new ([NPCD_START]);
    }
    $proc->run();
}


##########################################################################
sub Configure($$) {
##########################################################################
    my ($self,$config)=@_;

    my $t = $config->getElement (PATH)->getTree;

    # Print npcd config file
    my $fh_npcd = CAF::FileWriter->new (NPCD_CONFIG_FILE);
    my $npcd = $t->{'npcd'};

    $self->print_npcd_file($fh_npcd,$npcd);

    # Print php config file
    my $fh_php = CAF::FileWriter->new (PHP_CONFIG_FILE);
    my $php = $t->{'php'};

	my $elem = $config->getElement(PATH . "php/");
	
    $self->print_php_file($fh_php,$php, $elem);

    # For each page specified write a config file    
    my $fh_page;
    my $pages = $t->{'pages'};

    while (my ($kp, $vp) = each (%$pages)) {
        my $page = $kp;

        $fh_page = CAF::FileWriter->new ("$pages_dir/$page.cfg");
		$self->print_page_file($fh_page,$vp);
        
    	$fh_page->close;
    }


    # For each template specified write a config file 
    my $fh_template;   
    my $templates = $t->{'templates'};
    while (my ($kt, $vt) = each (%$templates)) {
        my $template = $kt;

        $fh_template = CAF::FileWriter->new (TEMPLATES_DIR_DEF . "/$template.php");
		$self->print_template_file($fh_template,$vt);
        
    	$fh_template->close;
    }
    
    # Reload the npcd service
    $self-> npcd_reload();
    	
    return; # return code is not checked.
}

1; # Perl module requirement.
