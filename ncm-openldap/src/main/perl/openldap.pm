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
use EDG::WP4::CCM::Element qw(unescape);

use constant PADDING => " "x4;
use constant SLAPTEST => qw(/usr/sbin/slaptest -f /proc/self/fd/0 -v);

# Prints the replica information for a database into $fh
sub print_replica_information
{
    my ($self, $fh, $tree) = @_;

    $self->verbose("Printing database replica information");
    my @flds = qw(syncrepl);

    if (exists($tree->{attrsonly})) {
    	push(@flds, "attrsonly");
    	delete($tree->{attrsonly});
    }

    if (exists($tree->{schemachecking})) {
	push(@flds, "schemachecking=" . ($tree->{schemachecking}?"on":"off"));
	delete($tree->{schemachecking});
    }

    if (exists($tree->{retry})) {
    	my $rt = sprintf(qq{retry="%s"},
    			 join(" ", map("$_->{interval} " .
				       ($_->{retries} ? $_->{retries} : '+'),
    				       @{$tree->{retry}})));
    	push(@flds, $rt);
    	delete($tree->{retry});
    }
    if (exists($tree->{attrs})) {
	my $rt = sprintf(qq{attrs="%s"},
			 join(",", @{$tree->{attrs}}));
	push(@flds, $rt);
	delete($tree->{attrs});
    }

    while (my ($k, $v) = each(%$tree)) {
	$v=qq{"$v"} if $v =~ m{=};
    	push(@flds, "$k=$v");
    }

    print $fh  join(" ", @flds), "\n";
}

# Prints a database or a backend section to $fh, based on the contents
# of the configuration $tree.
sub print_database_class
{
    my ($self, $fh, $type, $tree) = @_;

    $self->verbose("Printing a $type of class $tree->{class}");

    print $fh "$type $tree->{class}\n";
    delete($tree->{class});


    foreach my $i (qw(add_content_acl hidden lastmod mirrormode
		      monitoring readonly)) {
	if (exists($tree->{$i})) { 
	    print $fh  "$i ", ($tree->{$i} ? "on":"off"), "\n";
	    delete($tree->{$i});
	}
    }

    if (exists($tree->{restrict})) {
	print $fh  join(" ", "restrict", @{$tree->{restrict}}), "\n";
	delete($tree->{restrict});
    }

    if (exists($tree->{limits})) {
	while (my ($k, $v) = each(%{$tree->{limits}})) {
	    print $fh  "limits ", unescape($k);
	    foreach my $i (qw(size time)) {
		foreach my $j (qw(soft hard)) {
		    if (exists($v->{$i}->{$j})) {
			print $fh "=$i.$j ",
			    ($v->{$i}->{$j} < 0 ?
			     "unlimited":$v->{$i}->{$j});
		    }
		}
	    }
	    print $fh "\n";
	}
	delete($tree->{limits});
    }

    if (exists($tree->{backend_specific})) {
	while (my ($k, $v) = each(%{$tree->{backend_specific}})) {
	    print $fh  join("\n", map("$k $_", @$v), "");
	}
	delete($tree->{backend_specific});
    }

    if (exists($tree->{suffix})) {
	print $fh qq{suffix "$tree->{suffix}"\n};
	delete($tree->{suffix});
    }

    while (my ($k, $v) = each(%$tree)) {
	print $fh  "$k $v\n" unless $k eq 'syncrepl';
    }

    if (exists($tree->{syncrepl})) {
	$self->print_replica_information($fh, $tree->{syncrepl});
	delete($tree->{syncrepl});
    }
}

# Prints the global options for the slapd.conf file.
sub print_global_options
{
    my ($self, $fh, $t) = @_;

    $self->verbose("Printing slapd global options");

    foreach my $i (@{$t->{access}}) {
	print $fh "access to $i->{what}";
	print $fh " by $i->{who}"
	    if exists($i->{who});
	print $fh " $i->{access}"
	    if exists($i->{access});
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

    $self->verbose("Validating the generated configuration");
    CAF::Process->new([SLAPTEST],
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

sub restart_slapd
{
    my $self = shift;

    $self->verbose("Restarting slapd with the new configuration");
    CAF::Process->new([SLAPRESTART],
		      log => $self)->run();
    if ($?) {
	$self->error("Failed to restart slapd");
    } else {
	$self->verbose("slapd restarted successfully");
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

    foreach my $i (@{$t->{include_schema}}) {
	print $fh "include $i\n";
    }

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
	$self->legacy_setup($config, $fh, $t);
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
    my ($self, $config, $fh, $t) = @_;

    $self->verbose("Running ", __PACKAGE__, " in legacy mode");

    my ($database, $suffix, $rootdn, $rootpw, $directory, $loglevel,
	$argsfile, $pidfile, $base, $ldap_config);



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
