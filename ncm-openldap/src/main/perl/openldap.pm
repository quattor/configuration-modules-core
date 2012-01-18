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
use CAF::FileWriter;
use CAF::Process;
use File::Path;
use File::Basename;

use Readonly;

use constant PADDING => " "x4;
use constant SLAPTEST => qw(/usr/sbin/slaptest -f /proc/self/fd/0 -v);

# Prints the replica information for a database into $fh
sub print_replica_information
{
    my ($self, $fh, $tree) = @_;

    my @flds = qw(syncrepl);

    $self->verbose("Printing database replica information");
    if (exists($tree->{attrsonly})) {
    	push(@flds, "attrsonly");
    	delete($tree->{attrsonly});
    }

    if (exists($tree->{schemachecking})) {
	push(@flds, "schemachecking=" . ($tree->{schemachecking}?"on":"off"));
	delete($tree->{schemachecking});
    }

    if (exists($tree->{retries})) {
    	my $rt = sprintf(qq{retries="%s"},
    			 join(" ", map("$_->{interval} $_->{retries}",
    				       @{$tree->{retries}})));
    	push(@flds, $rt);
    	delete($tree->{retries});
    }

    while (my ($k, $v) = each(%$tree)) {
    	push(@flds, "$k=$v");
    }

    print $fh PADDING, join(" ", @flds), "\n";
}

# Prints a database or a backend section to $fh, based on the contents
# of the configuration $tree.
sub print_database_class
{
    my ($self, $fh, $type, $tree) = @_;

    print $fh "$type $tree->{class}\n";
    delete($tree->{class});

    foreach my $i (qw(add_content_acl hidden lastmod mirrormode
		      monitoring readonly)) {
	if (exists($tree->{$i})) { 
	    print $fh PADDING, $i, ($tree->{$i} ? "on":"off"), "\n";
	    delete($tree->{$i});
	}
    }

    if (exists($tree->{restrict})) {
	print $fh PADDING, join(" ", "restrict", @{$tree->{restrict}}), "\n";
	delete($tree->{restrict});
    }

    if (exists($tree->{limits})) {
	while (my ($k, $v) = each(%{$tree->{limits}})) {
	    print $fh PADDING, "limits $k";
	    print $fh " size.soft $v->{size}->{soft}"
		if exists($v->{size}->{soft});
	    print $fh " size.hard $v->{size}->{hard}"
		if exists($v->{size}->{hard});
	    print $fh " time.soft $v->{time}->{soft}"
		if exists($v->{time}->{soft});
	    print $fh " time.soft $v->{time}->{hard}"
		if exists($v->{time}->{hard});
	    print $fh "\n";
	}
	delete($tree->{limits});
    }

    while (my ($k, $v) = each(%$tree)) {
	print $fh PADDING, "$k $v\n";
    }
}

# Prints the global options for the slapd.conf file.
sub print_global_options
{
    my ($self, $fh, $t) = @_;

    foreach my $i (@{$t->{access}}) {
	print $fh "access to $i->{what}";
	print $fh " by $i->{who}"
	    if exists($i->{who});
	print $fh " $i->{what}"
	    if exists($i->{what});
	print $fh " $i->{control}"
	    if exists($i->{control});
	print $fh "\n";
    }

    delete($t->{access});

    print $fh map("authz-regexp $_->{match} $_->{replace}\n",
		  @{$t->{"authz-regexp"}});
    delete($t->{"authz-regexp"});


    foreach my $i (qw(gentlehup reverse-lookup)) {
	print $fh "$i ", $t->{$i} ? "on":"off", "\n"
	    if exists($t->{$i});
	delete($t->{$i});
    }

    foreach my $i (qw(attributetype ditcontentrule ldapsyntax objectclass)) {
	next unless exists($t->{$i});
	print $fh "$i ";
	while (my ($k, $v) = each(%{$t->{$i}})) {
	    print $fh " $k $v";
	}
	print $fh "\n";
	delete($t->{$i});
    }

    while (my ($k, $v) = each(%$t)) {
	if (!ref($v)) {
	    print $fh "$k $v";
	} elsif (ref($v) eq 'ARRAY') {
	    print $fh join(" ", $k, @$v);
	}
	print $fh "\n";
    }
}

# Returns whether the contents of $fh are a valid configuration for
# SLAPD, that would allow to reload the service.
sub valid_config
{
    my ($self, $fh) = @_;

    $self->verb("Validating the generated configuration");
    my $cmd = CAF::Process->new($SLAPTEST,
				log => $self,
				stdin => "$fh",
				stdout => \my $out,
				stderr => \my $err)->execute();

    if ($?) {
	$fh->cancel();
	$self->error("Invalid slapd configuration generated");
	$self->info("Standard output: $out");
	$self->info("Standard error: $err");
    } else {
	$self->verbose("Generated output: $out\n$err");
    }

    return !$?;
}

sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement($self->prefix())->getTree();

    my $fh = CAF::FileWriter->new($t->{conf_file},
				  log => $self,
				  backup => '.old');

    # We may have to run things in the legacy mode. Hopefully this
    # will get removed.
    if ($t->{database} eq '') {
	$self->print_global_options($fh, $t->{global_options});
	foreach my $i (@{$t->{backends}}) {
	    $self->print_database_class($fh, "backend", $i);
	}
	foreach my $i (@{$t->{databases}}) {
	    $self->print_database_class($fh, "database", $i);
	}
    } else {
	$self->legacy_setup($config, $fh);
    }

    if ($self->valid_config($fh)) {
	$self->restart_slapd();
	return 1;
    }
    return 0;
}

# Prints the slapd.conf file according to the previous, older, less
# accurate schema.
sub legacy_setup
{
    my ($self, $config, $fh) = @_;

    foreach my $i (@{$t->{include_schema}}) {
	print $fh "include $i\n";
    }



    # get values if elements exist
    if ($config->elementExists("$base/database")) {
	$database = $config->getValue("$base/database");
	print $fh "database $database\n";
    }

    if ($config->elementExists("$base/suffix")) {
	$suffix = $config->getValue("$base/suffix");
	print $fh "suffix $suffix\n";
    }

    if ($config->elementExists("$base/rootdn")) {
	$rootdn = $config->getValue("$base/rootdn");
	print $fh "rootdn $rootdn\n";
    }

    if ($config->elementExists("$base/rootpw")) {
	$rootpw = $config->getValue("$base/rootpw");
	print $fh "rootpw $rootpw\n";
    }

     if ($config->elementExists("$base/directory")) {
	$directory = $config->getValue("$base/directory");
	print $fh "directory $directory\n";
    }

    print $fh "\n";

    if ($config->elementExists("$base/loglevel")) {
	$loglevel = $config->getValue("$base/loglevel");
	print $fh "loglevel $loglevel\n";
    }

    if ($config->elementExists("$base/pidfile")) {
	$pidfile = $config->getValue("$base/pidfile");
	print $fh "pidfile $pidfile\n";
    }

    if ($config->elementExists("$base/argsfile")) {
	$argsfile = $config->getValue("$base/argsfile");
	print $fh "argsfile $argsfile\n";
    }

    print $fh "\n";

    my $index_entries = $ldap_config->{index};
    if($index_entries) {
   	for my $entry (@{$index_entries}) {
	    print $fh "index $entry\n";
	}
    }

    print $fh "\n";

    $fh->close();

    return 1;
}

1;    # Required for PERL modules
