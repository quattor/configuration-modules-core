# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::postgresql;

use strict;
use warnings;

use parent qw(NCM::Component);

use NCM::Component::Postgresql::Service qw($POSTGRESQL);

use LC::Exception;
our $EC = LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element;

use File::Copy;
use File::Path;
use File::Compare;

# for units etc
use MIME::Base64;
use Digest::MD5 qw(md5_hex);

use Readonly;

Readonly my $MAIN_CONFIG_TT => 'main_config';
Readonly my $HBA_CONFIG_TT => 'hba_config';

# relative to self->prefix
Readonly my $CONFIG_REL => '/config';
Readonly my $MAIN_CONFIG_REL => $CONFIG_REL.'/main';
Readonly my $HBA_CONFIG_REL => $CONFIG_REL.'/hba';

# v is some sort of context / content / key=value of each file
# p is a per file detail (e.g. format)
my (%v, %p);

# only ncm-dcache code
#   slurp
#   case_insensitive (slurp -> capit)
#   EQUAL_SPACE
#   ALL_POOL

=pod

=head1 DESCRIPTION

The component to configure postgresql databases

=head1 public methods

=over

=item create_postgresql_mainconfig

Create a TextRender instance with the main configuration data. Returns undef on failure.

=cut

sub create_postgresql_mainconfig
{
    my ($self, $config);

    my $base = $self->prefix().$MAIN_CONFIG_REL;
    if (! $config->elementExists($base)) {
        $self->error("create_postgresql_mainconfig: main config $base not found.");
        return;
    };

    my $trd = EDG::WP4::CCM::TextRender->new(
        $MAIN_CONFIG_TT,
        $config->getElement($base),
        relpath => 'postgresql',
        log => $self,
        );
    if(! $trd) {
        $self->error("Failed to render main postgresql config: $trd->{fail}");
        return;
    }

    return $trd;
}

=item create_postgresql_hbaconfig

Create a TextRender instance with the hba configuration data. Returns undef on failure.

=cut

sub create_postgresql_hbaconfig
{
    my ($self, $config);

    my $base = $self->prefix().$HBA_CONFIG_REL;
    if (! $config->elementExists($base)) {
        $self->error("create_postgresql_mainconfig: hba config $base not found.");
        return;
    };

    # pass whole config, the TT file expects a hashref with element hba
    my $trd = EDG::WP4::CCM::TextRender->new(
        $MAIN_CONFIG_TT,
        $config->getElement($self->prefix().$CONFIG_REL),
        relpath => 'postgresql',
        log => $self,
        );
    if(! $trd) {
        $self->error("Failed to render main postgresql config: $trd->{fail}");
        return;
    }

    return $trd;
}


=item fetch

Get C<$path> from C<$config>, if it does not exists, return C<$default>.
If C<$default> is not defined, use empty string as default.

If C<$path> is a relative path, it is assumed relative from C<$self->prefix>.

=cut

# TODO: move to NCM::Component? (with a better name)

sub fetch
{
    my ($self, $config, $path, $default) = @_;

    $default = '' if (! defined($default));

    $path = $self->prefix."/$path" if ($path !~ m/^\//);

    my $value;
    if ($config->elementExists($path)) {
        $value = $config->getValue($path);
    } else {
        $value = $default;
    }

    return $value;
}

=item version

Return arrayref with [major, minor, remainder] version information (from postmaster --version)

=cut

sub version
{
    my ($self, $pg_engine) = @_;

    my $cmd="$pg_engine/postmaster --version";
    my $out=`$cmd`;
    if ($out) {
        if ($out =~ m/(\d+)\.(\d+).(\d+)\s*$/) {
        }
    }
    # warn if something goes wrong
}

=item initdb

Initialise the database

=cut

sub initdb
{

    my ($self, $iam) = @_;

    # check version
    # if /usr/pgsql-9.2/bin/postgresql92-setup, exists, use it with initdb arg
    # else, if > 8.2, try service initdb
    # else, just start
}

# Return undef on fauilure, no errors

sub prepare_service
{
    my ($self, $default, $name) = @_;

    # query/set via NCM::Component::Systemd ?

    # this is not a sysconfig file, it's in a subdir

    $p{$name}{filename} = "/etc/sysconfig/pgsql/$name";
    $p{$name}{mode} = "BASH_SOURCE";
    $p{$name}{epilogue} = "if [ -f /etc/sysconfig/pgsql_shared ]\nthen\n  . /etc/sysconfig/pgsql_shared\nfi\n";

    # fro units, it's like
    # .include /lib/systemd/system/postgresql.service
    # [Service]
    # Environment=PGPORT=5433
    # --> also requires restart/reload --> add to systemd

    # this one comes with the installation
    my $pg_etc_init_def = "/etc/init.d/$default";

    if (! -e $pg_etc_init_def) {
        $self->warn("Defautl service $default not found.",
                     " Check your postgres installation.");
        return;
    }
    if ($name ne $default) {
        # this one comes with ncm-chkconfig
        if (! -e "/etc/init.d/$name") {
            $self->warn("Service $name not found.",
                         " Should be configured via one of the service component.");
            return;
        }
    }
}

=item whomai

Return a hashref with configuration related data to indentify
the service to use

=over

=item pg_engine

Location and name of service

=item service

Service instance to use

=item version

Return value from C<version> method

=item suffix

Version related suffix (or empty string if none is required).
E.g. '-9.2', part of e.g. default servicename, pg_engine, ...

=item exesuffix

Version related suffix for certain executables, like '92' in
'postgresql92-setup'.

=back

Return hashref or undef on failure. No errors are logged

=cut

sub whoami
{
    my ($self, $config) = @_;

    my $iam = {};

    my $pg_engine = $self->fetch($config, "pg_engine", "/usr/bin/");
    $iam->{pg_engine} = $pg_engine;
    $self->verbose("iam pg_engine $iam->{pg_engine}");

    $iam->{version} = $self->version($pg_engine);
    return if (! $iam->{version});

    $self->verbose("iam version ", join(' . ', @{$iam->{version}}), '.');

    my $pg_version = $self->fetch($config, "pg_version", "");
    my $pg_version_suf = $pg_version ? "-$pg_version" : "";
    $iam->{suffix} = $pg_version_suf;
    $self->verbose("iam suffix $iam->{suffix}");

    my $exesuffix_def = $pg_version;
    $exesuffix_def =~ s/\.//g;
    $iam->{exesuffix} = $self->fetch($config, "bin_version", $exesuffix_def);
    $self->verbose("iam exesuffix $iam->{exesuffix}");

    my $default_service = "$POSTGRESQL$iam->{suffix}";
    my $service = $self->fetch($config, "pg_script_name", $default_service);

    return if (! $self->prepare_service());

    my $srv = NCM::Component::Postgresql::Service->new(name => $service, log => $self);
    if ($srv) {
        $self->verbose("iam service instance created for name $service");
    } else {
        $self->warn("Failed to create service instance with name $service");
        return;
    }

    $iam->{service} = $srv;
    $self->verbose("iam service $iam->{service}");

    return $iam;
}

sub Configure {
    my ($self, $config) = @_;

    my $iam = $self->whoami($config);
    if (! $iam) {
        $self->error('Failed to determine setup details. (See errors/warnings above).');
        return 0;
    };

  ## proposed structure
  ## first generate all config in a way that does not depend on running subsystem.
  ## All start/stop/restart/reload of services can be flagged and dealt with later.

    my ($name, $real_exec, $serv, $sym, $link);

    my @all_names = ("pg_script", "pg_conf", "pg_hba", "pg_alter");
    foreach $name (@all_names) {
        $p{$name}{changed} = 0;
    }

    $pg_dir = $self->fetch($config, "pg_dir", "/var/lib/pgsql");
    $v{$name}{PGDATA} = "$pg_dir/data";
    $v{$name}{PGPORT} = $self->fetch($config, "pg_port", "5432");
    $v{$name}{PGLOG} = "$pg_dir/pgstartup.log";
    dump_it($name, "WRITE");

    # postgresql.conf
    $name="pg_conf";
    $p{$name}{mode} = "PLAIN_TEXT";
    $p{$name}{filename} = "$pg_dir/data/postgresql.conf";
    $p{$name}{write_empty} = 0;
    if ($config->elementExists($self->prefix().$MAIN_CONFIG_REL)) {
        $v{$name}{PURE_TEXT} = $self->create_postgresql_mainconfig($config);
    } else {
        $v{$name}{PURE_TEXT} = $self->fetch($config, "postgresql_conf");
    }
    # pg_hba.conf
    $name = "pg_hba";
    $p{$name}{mode} = "PLAIN_TEXT";
    $p{$name}{filename} = "$pg_dir/data/pg_hba.conf";
    $p{$name}{write_empty} = 0;
    if ($config->elementExists($self->prefix().$HBA_CONFIG_REL)) {
        $v{$name}{PURE_TEXT} = $self->create_postgresql_hbaconfig($config);
    } else {
        $v{$name}{PURE_TEXT} = $self->fetch($config, "pg_hba");
    }

    # we're going to use this file to check if one should run the "ALTER ROLE" commands.
    # if not, i think running pg_alter unnecessary might cause transfer errors.
    # to protect the passwds, the file will contain md5 hashes of the psql commands
    $name = "pg_alter";
    $p{$name}{mode} = "MD5_HASH";
    $p{$name}{filename} = "$pg_dir/data/pg_alter.ncm-".$self->name();
    $p{$name}{write_empty} = 0;

    # it's possible that $pg_dir/data doesn't yet exist.
    # we assume this is only due to pre-init postgres
    if ((! -d "$pg_dir/data") || (! -f "$pg_dir/data/PG_VERSION")) {
        $pg_data_dir_create = 1;
        $p{pg_conf}{changed} = 1;
        $p{pg_hba}{changed} = 1;
    } else {
        # ok, we're gonna do dummy write here and real write later
        dump_it("pg_conf");
        dump_it("pg_hba");
    }

##################################################################################
##################################################################################
#  starting part 2. dynamic config.
#  includes all service checks and config changes that need running services.
    $self->verbose("Checking current status. Will be the same status after the component finishes.");
    my $current_status = $iam->{service}->status();
    $self->verbose("Current status: $current_status.");

    $self->debug(2, "Starting some additional checks.");
    # other things that might go wrong. and need some rerunning of things:
    # aha, another one:
    my $moved_suffix="-moved-for-postgres-by-ncm-".$self->name().`date +%Y%m%d-%H%M%S`;
    chomp($moved_suffix);
    if ((-d "$pg_dir/data") && (! -f "$pg_dir/data/PG_VERSION")) {
          # ok, postgres will never like this
        # can't believe it will be running
        $iam->{service}->status_stop();
          # non-destructive mode on
          my $tmp_name_1="$pg_dir/data";
          if (move($tmp_name_1,$tmp_name_1."$moved_suffix")) {
              $self->info("Moved ".$tmp_name_1." to ".$tmp_name_1."$moved_suffix.");
        } else {
            # it will never work, but next time make sure all goes well
            $self->error("Can't move ".$tmp_name_1." to ".$tmp_name_1."$moved_suffix. Please clean up.");
            return 1;
        }
    }
    $self->debug(2, "Starting real configuration.");
###############################################################
###############################################################
    # remap flags to service calls
    my ($pgsql_restart,$pgsql_reload);

    $pgsql_reload = $p{pg_hba}{changed};
    $pgsql_restart=($p{pg_script}{changed} ||$p{pg_conf}{changed});

      if ($pgsql_restart) {
          $self->info("Restarting $iam->{service}.");
          $iam->{service}->status_stop();
          if ($pg_data_dir_create) {
              # create correct dir, which should now be created by the init script and restart
              # there are no backup files
              if (-d "$pg_dir/data") {
                # you should never get here
                $self->error("Directory $pg_dir/data exists but pg_data_dir_create is flagged?? Oops. Should not happen.");
                return 1;
            } else {
                # determine initialisation
                # starting from 8.2, initdb is a separate postgres call
                # lets assume postmaster is there
                my $cmd="$pg_engine/postmaster --version";
                my $out=`$cmd`;
                if ($out) {
                    if ($out =~ m/(\d+)\.(\d+).(\d+)\s*$/) {
                        my $doInitdb = 0;
                        if (($1 > 8)){
                            $doInitdb = 1;
                        } elsif ($1 == 8) {
                            if ($2 >= 2 ){
                                $doInitdb = 1;
                            }
                        }
                        if ($doInitdb) {
                            # postgres 8.2+
                            $self->info("Initdb $iam->{service} to trigger the initialisation (found release $1.$2.$3 > 8.2).");
                            return 1 if (! $iam->{service}->forcerestartinitdb_service());

                        } else {
                            $self->info("Starting $iam->{service} to trigger the initialisation (found release $1.$2.$3 < 8.2).");
                            return 1 if (! $iam->{service}->forcerestart_service());
                        };

                        $iam->{service}->status_stop();
                    } else {
                        $self->error("Command \"$cmd\" returns \"$out\" but this script doesn't expect it. (If you think it's a bug, please conatct the maintainer of this component). Exiting...");
                        return 1;
                    };
                } else {
                    $self->error("Command \"$cmd\" returns nothing (Probably doesn't exist). Exiting...");
                    return 1;
                };

            }
          }

          $name="pg_conf";
        $self->debug(1, "p{$name}{changed}: ".$p{$name}{changed});
        if ($p{$name}{changed}) {
            $self->info("Config of $name changed. Writing...");
            dump_it($name,"WRITE");
        }
        $iam->{service}->forcerestart_service();
      }
    # do some additional checks:
    if (! -d "$pg_dir/data") {
        # you should really never get here
        $self->error("Directory $pg_dir/data does not exist. Initialisation must have failed. (2)");
        return 1;
    }
    # so now it should be at least startable, but actually should be already running here...
    # maybe nothing changed, but postgres was down.
    return 1 if (! $iam->{service}->abs_start_service());

    if ($pgsql_reload) {
          $self->info("Reloading $iam->{service}.");
          $name="pg_hba";
        $self->debug(1, "p{$name}{changed}: ".$p{$name}{changed});
        if ($p{$name}{changed}) {
            $self->info("Config of $name changed. Writing...");
            dump_it($name,"WRITE");
        }

          return 1 if(! $iam->{service}->reload_service());
    # so now it actually should be already running here...
    # maybe reload did something stupid
          return 1 if (! $iam->{service}->abs_start_service());

    # so now we have a running postgres

    # run the alter command
    if ($iam->{service}->status()) {
        # it should be here
        if (! pg_alter($self->prefix())) {
            $self->error("Something went wrong during the addition of roles and/or databases. This must be cleared first.");
            return 1;
        }
    }
    # can the alter script make postgres go down. probably not, anyway ...
          return 1 if ($iam->{service}->abs_start_service());

#############
############# safe to assume that postgres is up and running here
#############




#######################################################################
#######################################################################
    # set postgres status to what it was
    $self->verbose("Setting status to what it was before the component ran.");
    if ($current_status) {
        $iam->{service}->status_start();
    } else {
        $iam->{service}->status_stop();
    }


############################################
## only subs now

##########################################################################
    sub pd {
##########################################################################
        my $text = shift;
        my $method = shift || "i";
        my $level = shift || "5";

        my $debug_print = 15;
        # force strings to numeric compare
        if ("$level" <= "$debug_print") {
            if ($method =~ m/^i/) {
                $self->info($text);
            } elsif ($method =~ m/^e/) {
                $self->error($text);
            } elsif ($method =~ m/^w/) {
                $self->warn($text);
            } else {
                $self->error("Unknown method $method in pd. Text was $text");
            }
        }
    }

##########################################################################
    sub sys2 {
##########################################################################
        # is a wrapper for system(). that's why it has these strange exitcodes
        # >0 is failure (the numeric values are not the same as in eg bash)
        # but it's the same as running with system($exec)
        my $exitcode=1;
        my @argg=@_;

        my $exec=shift;
        my $use_system = shift || "true";
        # needs $use_system==0
        my $return_both = shift || "false";
        my $pd_val=5;
        if ($return_both eq "nothing") {
            $pd_val = "1000000";
        }

        my $func = "sys2";
        pd("$func: function called with arg: @argg","i",$pd_val+5);

        my $output ="";

        if ($use_system eq "true") {
            system($exec);
            $exitcode=$?;
            pd("$func:exec: $exec","i",$pd_val);
            pd("$func:exitcode: $exitcode","i",$pd_val);
        } else {
            if (! open(FILE,$exec." 2>&1 |")){
                pd("$func: exec=$exec: $!","e","i",$pd_val);
            } else {
                $output="";
                pd("$func: Processing FILE now","i",$pd_val+13);
                while(<FILE>) {
                    pd("$func: Processing FILE now: $_",,"i",$pd_val+13);
                    $output .= $_;
                }
                close(FILE);
                $exitcode=$?;
                pd("$func:exec: $exec","i",$pd_val);
                pd("$func:output: ".$output,"i",$pd_val);
                pd("$func:exitcode: $exitcode","i",$pd_val);
            }
        }
        if ( ($use_system ne "true") && ($return_both eq "true")) {
            return ($exitcode,$output);
        } else {
            return $exitcode;
        }
    }


##########################################################################
    sub dump_it {
##########################################################################
        my $func = "dump_it";
        $self->debug(1, "$func: function called with arg: @_","i",10);
        my $name = shift;
        my $extra_mode = shift || "DUMMY_WRITE_SET";

        my $file_name=$p{$name}{filename};
        my $mode=$p{$name}{mode}."_".$extra_mode;

        my $changed = 0;
        my $suffix=".back";
        $self->debug(1, "$func: Start with name=$name mode=$mode filename=$file_name");

        my $backup_file = $file_name.$suffix;
        my $backup_file_tmp = $backup_file.$suffix;
        if (-e $file_name) {
            copy($file_name, $backup_file_tmp) || $self->error("Can't create backup $backup_file_tmp: $!");
        } else {
            $self->verbose("Can't create backup $backup_file_tmp: no current version found");
        }
        open(FILE,"> ".$file_name) || $self->error("Can't write to $file_name: $!");
        if ($mode !~ m/NO_COMMENT/) {
            print FILE "## Generated by ncm-".$self->comp()."\n## DO NOT EDIT\n";
        }
        if ($p{$name}{prologue}) {
            print FILE "\n".$p{$name}{prologue}."\n";
        }
        # ok, without the sort, you are garanteed to see some strange behaviour.
        foreach my $k (sort keys(%{$v{$name}})) {
            # ok, lets inplement some special values here:
            if ((exists $p{$name}{write_empty}) && ($p{$name}{write_empty} == 0) && ( "X".$v{$name}{$k} eq "X")) {
                # do nothing, print message
                $self->warn("Nothing specified for $name and key $k. Not writing to $file_name.")
            } elsif ($mode =~ m/PLAIN_TEXT/) {
                print FILE $v{$name}{$k};
        } elsif ($mode =~ m/BASH_SOURCE/)  {
            # if there are spaces in the value, quote the whole line
            # in principle for source it doesn't matter, but in this way individual values can be used as names etc
            if ($v{$name}{$k} =~ m/ |=/) {
                print FILE "$k=\"$v{$name}{$k}\"\n";
            } else {
                print FILE "$k=$v{$name}{$k}\n";
            }
        } elsif ($mode =~ m/MD5_HASH/) {
            # what could possibly go wrong here?
            my $md5=md5_hex($v{$name}{$k});
            print FILE "$k=$md5\n";
        }  else {
               $self->error("Dump_it: Using mode $mode, but doesn't match.");
           }
        }
        if ($p{$name}{epilogue}) {
            print FILE "\n".$p{$name}{epilogue}."\n";
        }
        close(FILE);
        # check for differences
        # if the file doesn't exists, compare will exit with -1, so this also checks existence of file
        if (compare($file_name,$backup_file_tmp) == 0) {
            # they're equal, remove backup
            unlink($backup_file_tmp) || $self->warn("Can't unlink ".$backup_file_tmp) ;
        } else {
            if (-e $backup_file_tmp) {
                if ($mode =~ m/DUMMY_WRITE_SET/) {
                    copy($backup_file_tmp, $file_name)  || $self->error("Can't move $backup_file_tmp to $file_name in mode $mode: $!");
                } else {
                    copy($backup_file_tmp, $backup_file) || $self->error("Can't create backup $backup_file: $!");
                }
            } else {
                if ($mode =~ m/DUMMY_WRITE_SET/) {
                    unlink($file_name) || $self->error("Can't unlink $file_name in mode $mode: $!");
                }
            }
            # flag the change here, action to be taken later
            $changed = 1;
        }

        if ($changed) {
            $p{$name}{changed}=1;
        } else {
            $p{$name}{changed}=0;
        }

        $self->debug(1, "$func: Stop with name=$name changed=$changed");
        return $changed;
    }


##########################################################################
    sub pg_alter {
##########################################################################
        my $func = "pg_alter";
        $self->debug(1, "$func: function called with arg: @_");

        my $new_base = shift;
        my $name="pg_alter";

        my $su;
        # taken from the init.d/postgresql script: For SELinux we need to use 'runuser' not 'su'
        if (-x "/sbin/runuser") {
            $su="runuser";
        } else {
            $su="su";
        }
        my $exitcode=1;
        # configure users/roles: list them with psql -t -c "SELECT rolname FROM pg_roles;"
        # a user is a role with the LOGIN attribute set
        my @all_roles=();
        open(TEMP,"$su -l postgres -c \"psql -t -c \\\"SELECT rolname FROM pg_roles;\\\"\" |")||$self->error("$func: SELECT rolname FROM pg_roles failed: $!");
        while(<TEMP>) {
            chomp;
            s/ //g;
            push(@all_roles,$_);
        }
        close TEMP;
        my ($exi,$real_exec);
        my ($role,$rol,$r,$rol_opt);
        if ($config->elementExists("$new_base/roles")) {
            my $roles = $config->getElement("$new_base/roles");
            while ($roles->hasNextElement() ) {
                $role = $roles->getNextElement();
                $rol = $role->getName();
                # check if role exists, if not create it
                $exi=0;
                foreach $r (@all_roles) {
                    if ($r eq $rol) { $exi=1;}
                }
                if (! $exi) {
                    $self->verbose("$func: Role $rol does not exist. Creating...");
                    $real_exec="$su -l postgres -c \"psql -c \\\"CREATE ROLE \\\\\\\"$rol\\\\\\\"\\\"\"";
                    $self->error("$func: Executing $real_exec failed") if (sys2($real_exec));
                }
                # set defined attributes to role
                $rol_opt = $role->getValue();
                $v{$name}{$rol}=$rol_opt;
            }
        }

        dump_it($name,"WRITE");
        if ($p{$name}{changed}) {
            # apparently something has changed.
            $self->verbose("$func: Something changed to the roles attributes.");
            foreach $rol (keys %{$v{$name}}) {
                $self->verbose("$func: Role $rol: setting attributes...");
                # run without logger!!
                $real_exec="$su -l postgres -c \"psql -c \\\"ALTER ROLE \\\\\\\"$rol\\\\\\\" ".$v{$name}{$rol}.";\\\"\"";
                # Passwds could be shown with this: $self->info("$real_exec");
                if (sys2($real_exec,"false","nothing")) {
                    $self->error("$func: Executing ALTER ROLE $rol failed (attributes not shown for passwd reasons)");
                    $exitcode=0;
                }
            }
        }

        my ($database,$datab,$datab_user,$datab_el,$datab_elem,$datab_file,$datab_sql_user,$datab_lang,$datab_lang_file);
        if ($config->elementExists("$new_base/databases")) {
            my $databases = $config->getElement("$new_base/databases");
            while ($databases->hasNextElement() ) {
                $database = $databases->getNextElement();
                $datab = $database->getName();
                $datab_el = $config->getElement("$new_base/databases/".$datab);
                $datab_file = "";
                $datab_lang = "";
                $datab_lang_file = "";
                $datab_sql_user= "REALLY_NOBODY";
                while ($datab_el->hasNextElement() ) {
                    $datab_elem = $datab_el->getNextElement();
                    $datab_user = $datab_elem->getValue() if ($datab_elem->getName() eq "user");
                    $datab_sql_user = $datab_elem->getValue() if ($datab_elem->getName() eq "sql_user");
                    $datab_file = $datab_elem->getValue() if ($datab_elem->getName() eq "installfile");
                    $datab_lang = $datab_elem->getValue() if ($datab_elem->getName() eq "lang");
                    $datab_lang_file = $datab_elem->getValue() if ($datab_elem->getName() eq "langfile");
                }
                $datab_sql_user = $datab_user if ($datab_sql_user eq "REALLY_NOBODY");
                $exitcode = create_pgdb($datab,$datab_user,$datab_file,$datab_lang,$datab_lang_file,$datab_sql_user);
            }
        }
        return $exitcode;
    }

##########################################################################
    sub create_pgdb {
##########################################################################
        my $func = "create_pgdb";
        $self->debug(1, "$func: function called with arg: @_");

        my $datab = shift;
        my $datab_user = shift;
        my $datab_file = shift;
        my $datab_lang = shift;
        my $datab_lang_file = shift;
        my $datab_run_sql_user = shift ||$datab_user;
        my $exitcode = 1;

        my $su;
        # taken from the init.d/postgresql script: For SELinux we need to use 'runuser' not 'su'
        if (-x "/sbin/runuser") {
            $su="runuser";
        } else {
            $su="su";
        }

        # configure databases: list all databases with psql -t -c "SELECT datname FROM pg_database;"
        my @all_databases=();
        open(TEMP,"$su -l postgres -c \"psql -t -c \\\"SELECT datname FROM pg_database;\\\"\" |")||$self->error("$func: SELECT datname FROM pg_database failed: $!");
        while(<TEMP>) {
            chomp;
            s/ //g;
            push(@all_databases,$_);
        }
        close TEMP;

        # check if database exists, if not create it
        my $exi=0;
        foreach my $d (@all_databases) {
            $exi=1 if ($d eq $datab);
        }
        if (! $exi) {
            $self->verbose("$func: Database $datab does not exist. Creating...");
            my $real_exec="$su -l postgres -c \"psql -c \\\"CREATE DATABASE \\\\\\\"$datab\\\\\\\" OWNER \\\\\\\"$datab_user\\\\\\\";\\\"\"";
            my ($exitcode,$output) = sys2($real_exec,"false","true");
            if (! $exitcode) {
                if (($datab_file ne "") && (-e $datab_file)) {
                    $self->verbose("$func: Creating $datab: initialising with $datab_file.");
                    $real_exec="$su -l postgres -c \"psql -U $datab_run_sql_user $datab -f $datab_file;\"";
                    ($exitcode,$output) = sys2($real_exec,"false","true");
                    if ($exitcode) {
                        $self->error("$func: Executing $real_exec failed:\n$output");
                        $exitcode=0;
                    }
                }
                # check for db lang
                if ($datab_lang ne "") {
                    $self->verbose("$func: Creating $datab: setting lang $datab_lang.");
                    $real_exec="$su -l postgres -c \"createlang $datab_lang $datab;\"";
                    ($exitcode,$output) = sys2($real_exec,"false","true");
                    if ($exitcode) {
                        $self->error("$func: Executing $real_exec failed:\n$output");
                        $exitcode=0;
                    } else {
                        # db lang init file
                        if (($datab_lang_file ne "") && (-e $datab_lang_file)) {
                            $self->verbose("$func: Creating $datab: initialising lang $datab_lang with $datab_lang_file.");
                            $real_exec="$su -l postgres -c \"psql -U $datab_run_sql_user $datab -f $datab_file;\"";
                            ($exitcode,$output) = sys2($real_exec,"false","true");
                            if ($exitcode) {
                                $self->error("$func: Executing $real_exec failed:\n$output");
                                $exitcode=0;
                            }
                        }
                    }
                }
            } else {
                $self->error("$func: Executing $real_exec failed with:\n$output");
            }
        }
        return $exitcode;
    }



### real end of configure
    return 1;
}



=pod

=back

=cut

1;
