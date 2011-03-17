################################################################################
# This is 'openldap.pm', a ncm-openldap's file
################################################################################
#
# VERSION:    1.0.0, 02/02/10 15:50
# AUTHOR:     Daniel Jouvenot <jouvenot@lal.in2p3.fr>
# MAINTAINER: Guillaume Philippon <philippo@lal.in2p3.fr>
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

package NCM::Component::openldap;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use LC::Process qw (output execute);
use EDG::WP4::CCM::Element;

use File::Path;
use File::Basename;

local(*DTA);

##########################################################################
sub Configure($$@) {
##########################################################################

    my $loglevel;
    my $pidfile;
    my $argsfile;
    my $database;
    my $suffix;
    my $rootdn;
    my $rootpw;
    my $directory;
    my $openldap_config_file;

    my ($self, $config) = @_;

    # Define paths for convenience. 
    my $base = "/software/components/openldap";

    if ($config->elementExists("$base/conf_file")) {
	$openldap_config_file = $config->getValue("$base/conf_file");
    } else {
	$openldap_config_file = '/tmp/test.conf';
    }

    # write the slapd.conf
    open(FILE, ">".$openldap_config_file);

    my $ldap_config = $config->getElement($base)->getTree();

    my $include_entries = $ldap_config->{include_schema};
    if($include_entries) {
   	for my $entry (@{$include_entries}) {
	    print FILE "include $entry\n";
	}
    }

    print FILE "\n";

    # get values if elements exist
    if ($config->elementExists("$base/database")) {
	$database = $config->getValue("$base/database");
	print FILE "database $database\n";
    }
    else {
	die "database element not found : $!";
    }

     if ($config->elementExists("$base/suffix")) {
	$suffix = $config->getValue("$base/suffix");
	print FILE "suffix $suffix\n";
    }
    else {
	die "suffix element not found : $!";
    }

     if ($config->elementExists("$base/rootdn")) {
	$rootdn = $config->getValue("$base/rootdn");
	print FILE "rootdn $rootdn\n";
    }
    else {
	die "rootdn element not found : $!";
    }

     if ($config->elementExists("$base/rootpw")) {
	$rootpw = $config->getValue("$base/rootpw");
	print FILE "rootpw $rootpw\n";
    }
    else {
	die "rootpw element not found : $!";
    }

     if ($config->elementExists("$base/directory")) {
	$directory = $config->getValue("$base/directory");
	print FILE "directory $directory\n";
    }
    else {
	die "directory element not found : $!";
    }

    print FILE "\n";

    if ($config->elementExists("$base/loglevel")) {
	$loglevel = $config->getValue("$base/loglevel");
	print FILE "loglevel $loglevel\n";
    }

    if ($config->elementExists("$base/pidfile")) {
	$pidfile = $config->getValue("$base/pidfile");
	print FILE "pidfile $pidfile\n";
    }

    if ($config->elementExists("$base/argsfile")) {
	$argsfile = $config->getValue("$base/argsfile");
	print FILE "argsfile $argsfile\n";
    }

    print FILE "\n";

    my $index_entries = $ldap_config->{index};
    if($index_entries) {
   	for my $entry (@{$index_entries}) {
	    print FILE "index $entry\n";
	}
    }

    print FILE "\n";

    close(FILE);

    return 1;
}

1;    # Required for PERL modules
