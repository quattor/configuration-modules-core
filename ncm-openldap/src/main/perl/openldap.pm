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
use File::Copy;
use EDG::WP4::CCM::Element qw(unescape);
use Encode qw(encode_utf8);


use constant SLAPTEST => qw(/usr/sbin/slaptest -v -u -f);
use constant SLAPRESTART => qw(/sbin/service slapd restart);

# fixed indentation for conf files
use constant INDENTATION => "    ";

use constant DB_CONFIG_SET => qw(
    cachesize
    lg_regionmax
    lg_bsize
    lg_max
);

sub create_db_config_file
{
    my ($self, $directory, $tree) = @_;
    if (-d $directory) {
        my $contents='';
        while (my ($k, $v) = each(%$tree)) {
            $k="set_$k" if (grep $_ eq $k, DB_CONFIG_SET);
            $v=join(" ",@$v) if (ref($v) eq "ARRAY");
            $contents.="$k $v\n";
        }

        # try to write it
        my $fname = "$directory/DB_CONFIG";
        my $result = LC::Check::file( $fname,
                                      contents => encode_utf8($contents),
                                      owner       => 'ldap',
                                      group       => 'ldap',
                                      mode        => 0440,
                                    );
        if ($result) {
            $self->info("DB_CONFIG updated (ldap not restarted).");
        } else {
            if (!defined($result)) {
                $self->error("$fname update failed");
            }
        }
    } else {
        $self->error("Directory $directory not found. Unable to create DB_CONFIG file (expect lower performance)");
    };
};

# monitoring
# default at end of slapd.conf (>= v2.4)
sub print_monitoring
{
    my ($self, $fh, $tree) = @_;
    # some default settings
    if (exists($tree->{default}) && $tree->{default}) {
        print $fh "\n","monitoring on","\n","database monitor","\n";
        delete($tree->{default});
    }
}

# Prints the overlays for a database into $fh
sub print_overlay
{
    my ($self, $fh, $overlay, $tree) = @_;

    my %overlay_boolean = (
        "syncprov" => ["nopresent","reloadhint"]
    );

    while (my ($k, $v) = each(%$tree)) {
        if (grep $_ eq $k, @{$overlay_boolean{$overlay}}) {
            $v = $v ? "TRUE" : "FALSE";
        } elsif (ref($v) eq "ARRAY") {
            $v=join(" ",@$v);
        }
        print $fh "$overlay-$k $v\n";
    };
}

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

    print $fh  join("\n".INDENTATION, @flds), "\n";
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

    if (exists($tree->{index})) {
        foreach my $ind (@{$tree->{index}}) {
            print $fh "index ",join(",",@{@$ind[0]})," ",join(",",@{@$ind[1]}),"\n";
        }
        delete($tree->{index});
    };


    if (exists($tree->{limits})) {
        while (my ($k, $v) = each(%{$tree->{limits}})) {
            print $fh  "limits ", unescape($k);
            foreach my $i (qw(size time)) {
                foreach my $j (qw(soft hard)) {
                    if (exists($v->{$i}->{$j})) {
                        print $fh " $i.$j=",
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

    if (exists($tree->{checkpoint})) {
        my $s = join(" ", $tree->{checkpoint});
        print $fh qq{checkpoint $s\n};
        delete($tree->{checkpoint});
    }

    if (exists($tree->{db_config})) {
        if (exists($tree->{directory})) {
            # deal with exit code? restart ldap when file changed?
            $self->create_db_config_file($tree->{directory},$tree->{db_config});
        } else {
            $self->error("db_config defined but not directory");
        }
        delete($tree->{db_config});
    }

    while (my ($k, $v) = each(%$tree)) {
        print $fh  "$k $v\n" unless (grep $_ eq $k, qw(syncrepl overlay updateref));
    }

    if (exists($tree->{syncrepl})) {
        $self->print_replica_information($fh, $tree->{syncrepl});
        delete($tree->{syncrepl});
    }

    # updateref should be put after syncrepl
    print $fh  "updateref ".$tree->{updateref}."\n" if (exists($tree->{updateref}));

    # overlays are last
    if (exists($tree->{overlay})) {
        while (my ($overlay, $overlaytree) = each(%{$tree->{overlay}})) {
            print $fh "overlay $overlay\n";
            $self->print_overlay($fh, $overlay, $overlaytree);
        }
        delete($tree->{overlay});
    }

    print $fh "\n";

}

# Prints the global options for the slapd.conf file.
sub print_global_options
{
    my ($self, $fh, $t) = @_;

    $self->verbose("Printing slapd global options");

    foreach my $access (@{$t->{access}}) {
        # what
        my $what;
        if (exists($access->{attrs})) {
            $what="attrs=".join(',',@{$access->{attrs}});
        } elsif (exists($access->{what})) {
            $what=$access->{what};
        } else {
            $self->error("No valid 'what' section for access (supported are 'what' and 'attrs')");
        }
        print $fh "access to $what";

        # by
        foreach my $by (@{$access->{by}}) {
            print $fh "\n".INDENTATION."by ".join(" ",@$by);
        }
        print $fh "\n";
    }
    delete($t->{access});

    while (my ($name, $value) = each(%{$t->{"tls"}})) {
        print $fh "TLS$name $value\n";
    }

    delete($t->{"tls"});

    print $fh map("moduleload $_\n",
              @{$t->{"moduleload"}});
    delete($t->{"moduleload"});


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

    print $fh "\n";
}

# Returns whether the contents of $fh are a valid configuration for
# SLAPD, that would allow to reload the service.
sub valid_config
{
    my ($self, $file) = @_;

    $self->verbose("Validating the generated configuration");
    my $cmd = CAF::Process->new([SLAPTEST],
                log => $self,
                stdout => \my $out,
                stderr => \my $err);

    $cmd->pushargs($file);
    $cmd->execute();

    if ($?) {
        $self->error("Invalid slapd configuration generated");
        $self->info("Standard output: $out");
        $self->info("Standard error: $err");
    } else {
        $self->verbose("Generated output: $out\n$err");
    }

    return !$?;
}

#Restarts the SLAPD daemon.
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

# Move slapd.d dir (newer, unsupported configuration method)
sub move_slapdd_dir
{
    my ($self,$slapdddir) = @_;

    if ( -d $slapdddir ) {
        my $origsuff = "orig.".time();
        $self->info("Moving slapd.d dir $slapdddir to $slapdddir.$origsuff.");
        move($slapdddir, "$slapdddir.$origsuff")  || $self->error("Moving $slapdddir to $slapdddir.$origsuff failed: $!");
    } else {
        $self->debug(2, "Moving slapd.d dir $slapdddir: no such dir found.");
    }
}

sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement($self->prefix())->getTree();

    my $backupsuff = ".".time();

    my $fh = CAF::FileWriter->new($t->{conf_file},
                  log => $self,
                  backup => $backupsuff,
                  owner => 'root',
                  group => 'ldap',
                  mode => 0440);

    foreach my $i (@{$t->{include_schema}}) {
        print $fh "include $i\n";
    }

    # We may have to run things in the legacy mode. Hopefully this
    # will get removed.
    if ($t->{database} eq '') {
        $self->print_global_options($fh, $t->{global});
        foreach my $i (@{$t->{backends}}) {
            $self->print_database_class($fh, "backend", $i);
        }
        foreach my $i (@{$t->{databases}}) {
            $self->print_database_class($fh, "database", $i);
        }
        $self->print_monitoring($fh,$t->{monitoring}) if (exists($t->{monitoring}));

        # move conf_dir/slapd.d
        if (exists($t->{move_slapdd}) && $t->{move_slapdd}) {
            $self->move_slapdd_dir(dirname($t->{conf_file})."/slapd.d");
        }
    } else {
        $self->legacy_setup($config, $fh, $t);
    }

    # We have to save unconditionally because slaptest doesn't read
    # from pipes. :(
    $fh->close();
    if ($self->valid_config($t->{conf_file})) {
        $self->restart_slapd();
        return 1;
    } else {
        $self->info("Restoring the old configuration file; invalid configuration file stored in $t->{conf_file}.invalid");
        move($t->{conf_file}, "$t->{conf_file}.invalid") || $self->error("Moving $t->{conf_file} to $t->{conf_file}.invalid failed: $!");
        if (-f "$t->{conf_file}$backupsuff") {
            move("$t->{conf_file}$backupsuff", $t->{conf_file})  || $self->error("Moving $t->{conf_file}$backupsuff to $t->{conf_file} failed: $!");
        } else {
            $self->info("Restoring the old configuration file: no backup file $t->{conf_file}$backupsuff found");
        }

    }
    return 0;
}

# Prints the slapd.conf file according to the previous, older, less
# accurate schema.
sub legacy_setup
{
    my ($self, $config, $fh, $t) = @_;

    $self->verbose("Running ", __PACKAGE__, " in legacy mode");

    my ($database, $suffix, $checkpoint, $rootdn, $rootpw, $directory, $loglevel,
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

    if ($config->elementExists("$base/checkpoint")) {
        my $checkpoint = join(" ", $config->getValue("$base/checkpoint"));
        print $fh "checkpoint $checkpoint";
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
