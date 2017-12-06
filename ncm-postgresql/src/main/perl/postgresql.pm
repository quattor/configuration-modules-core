#${PMcomponent}

use parent qw(NCM::Component);

use NCM::Component::Postgresql::Service qw($POSTGRESQL);
use NCM::Component::Postgresql::Commands;

use LC::Exception qw(SUCCESS);
our $EC = LC::Exception::Context->new->will_store_all;
use CAF::Object;

use POSIX qw(strftime);
use Digest::MD5 qw(md5_hex);
use File::Copy qw(move);

use Readonly;

our $NoActionSupported = 1;

Readonly my $SYSCONFIG_TT => 'sysconfig';

# relative to self->prefix
Readonly my $CONFIG_REL => '/config';

# relative filename in PGDATA
# legacy full text config relative to sefl->prefix
Readonly::Hash our %MAIN_CONFIG => {
    NAME => 'main',
    TT => 'main_config',
    CONFIG => $CONFIG_REL.'/main',
    CONFIG_EL => $CONFIG_REL.'/main',
    FILENAME => 'postgresql.conf',
    TEXT => 'postgresql_conf',
};

Readonly::Hash our %HBA_CONFIG => {
    NAME => 'hba',
    TT => 'hba_config',
    CONFIG => $CONFIG_REL.'/hba',
    CONFIG_EL => $CONFIG_REL, # TT file expects this
    FILENAME => 'pg_hba.conf',
    TEXT => 'pg_hba',
};

Readonly::Hash our %PG_ALTER => {
    NAME => 'pg_alter',
    TT => 'pg_alter',
    CONFIG => '/roles',
    CONFIG_HASHREF => undef, # added in a copy later
};

Readonly my $DEFAULT_PORT => 5432;
Readonly my $DEFAULT_BASEDIR => "/var/lib/pgsql";

# TODO:
#    - what does the pg_version do?
#    - service status logs errors just because the service is not running
#       - but for status, that's ok

=pod

=head1 DESCRIPTION

The component to configure postgresql databases

=head1 public methods

=over

=item create_postgresql_config

Create main or hba config via textrender. Returns undef on failure, changed state otherwise.
The C<data> hash is either C<%MAIN_CONFIG> or C<%HBA_CONFIG>;
or the pg_alter hashref (see C<pg_alter> method).

=cut

sub create_postgresql_config
{
    my ($self, $config, $iam, %data) = @_;

    my $fh;
    my $filename = "$iam->{pg}->{data}/$data{FILENAME}";
    # default empty string, so can be used as boolean
    my $text = $self->fetch($config, $data{TEXT});

    # new style precedes
    if ($config->elementExists($self->prefix().$data{CONFIG})) {
        $self->verbose("rendering $data{NAME} configuration data");

        my $configdata;
        if($data{CONFIG_EL}) {
            $configdata = $config->getElement($self->prefix().$data{CONFIG_EL});
        } elsif ($data{CONFIG_HASHREF}) {
            $configdata = $data{CONFIG_HASHREF};
        } else {
            $self->error('Cannot find configdata: CONFIG_EL and CONFIG_HASHREF are missing',
                         ' (bug in component).');
            return;
        }

        my $trd = EDG::WP4::CCM::TextRender->new(
            $data{TT},
            $configdata,
            relpath => 'postgresql',
            log => $self,
            );

        $fh = $trd->filewriter($filename, log => $self);
        if(! defined($fh)) {
            $self->error("Failed to render $data{NAME} postgresql config: $trd->{fail}");
            return;
        }
    } elsif ($text) {
        $self->verbose("legacy full text $data{NAME} configuration data");
        $fh = CAF::FileWriter->new($filename, log => $self);
        print $fh $text;
    } else {
        $self->error("No config paths found for $data{NAME} config (CONFIG $data{CONFIG}) and empty text.");
        return;
    };

    return $fh->close() ? 1 : 0;
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

    return $default if(! defined($path));

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

Return undef in case of problem.

=cut

sub version
{
    my ($self, $pg_engine) = @_;

    my $proc = CAF::Process->new(
        ["$pg_engine/postmaster", "--version"],
        log => $self,
        keeps_state => 1,
        );
    my $output = $proc->output();

    # e.g. 'postgres (PostgreSQL) 9.2.1'
    if ($output && $output =~ m/\s(\d+)\.(\d+).(\d+)\s*$/) {
        return [$1, $2, $3];
    } else {
        $self->error("Failed to parse output from $proc: $output");
        return;
    }
}

=item initdb

Initialise the database. End result is a stopped initialised database.

Returns undef on failure.

=cut

sub initdb
{

    my ($self, $iam) = @_;

    $self->info("Initdb, stopping $iam->{service}.");
    $iam->{service}->status_stop();

    # if /usr/pgsql/bin/postgresql-setup, exists, use it with initdb arg
    # else, if >= 8.2, try service postgresql initdb
    # else, just start

    my $setup = "$iam->{pg}->{engine}/postgresql$iam->{exesuffix}-setup";
    my $is_recent_enough = (($iam->{version}->[0] > 8) ||
                            (($iam->{version}->[0] == 8 ) && $iam->{version}->[1] >= 2));
    $self->verbose("initdb with setup $setup and is_recent_enough $is_recent_enough");
    if ($self->_file_exists($setup)) {
        $self->verbose("initdb with setup $setup");
        my $proc = CAF::Process->new([$setup, 'initdb'], log => $self);
        my $output = $proc->output();

        if ($?) {
            $self->error("Failed to initialise the database with setup $setup.");
            return;
        }
    } elsif ($is_recent_enough) {
        $self->verbose("initdb without setup $setup, but with initdb service action");
        return if (! $iam->{service}->initdb());
    } else {
        $self->verbose("initdb with old version. Just going to start and hope all will be ok.");
        return if (! $iam->{service}->status_start());
    }

    # initdb ends with stopped service (configuration still needs to happen)
    return if(! $iam->{service}->status_stop());

    return SUCCESS;
}


=item prepare_service

Perform installation sanity check, and generates the
pgsql sysconfig entry.

Returns undef on failure, the changed state of the pgsql
sysconfig file otherwise

=cut

# for units, you need a new unit with content like
# ncm-systemd can do this for you (set replace = true)
# .include /lib/systemd/system/postgresql.service
# [Service]
# Environment=PGPORT=5433

# TODO: how do we check this, esp PGDATA and PGPORT

sub prepare_service
{
    my ($self, $iam) = @_;

    my ($svc_def_fn, $svc_fn) = $iam->{service}->installation_files($iam->{defaultname});

    if (! $self->_file_exists($svc_def_fn)) {
        $self->error("Default service file $svc_def_fn for service $iam->{defaultservice} not found.",
                     " Check your postgres OS installation.");
        return;
    }

    if (! $self->_file_exists($svc_fn)) {
        $self->error("Service file $svc_fn for service $iam->{servicename} not found.",
                    " Should be configured through one of the service components.");
        return;
    }

    # this is not a file controllable with ncm-sysconfig, it's in a subdir
    # the directory seems present even on linux_systemd (altough unused)
    my $sysconfig_data;
    foreach my $var (qw(data log port)) {
        $sysconfig_data->{"pg$var"} = $iam->{pg}->{$var};
    }

    my $sysconfig_fn = "/etc/sysconfig/pgsql/$iam->{servicename}";
    my $trd = EDG::WP4::CCM::TextRender->new(
        $SYSCONFIG_TT,
        $sysconfig_data,
        relpath => 'postgresql',
        log => $self,
        );
    my $fh = $trd->filewriter(
        $sysconfig_fn,
        log => $self,
        );
    if($fh) {
        my $changed = $fh->close() ? 1 : 0; # force to 0/1
        return $changed;
    } else {
        $self->error("Failed to render postgresql sysconfig $sysconfig_fn: $trd->{fail}");
        return;
    }
}

=item whoami

Return a hashref with configuration related data to indentify
the service to use

=over

=item service

Service instance to use

=item version

Return value from C<version> method

=item pg

A hashref with postgresql basic configuration data,
required to start the database.

=over

=item dir

The database base directory

=item data

The database 'data' subdirectory

=item port

The database port

=item log

The database startup log

=item engine

Location of service binaries

=back

=item suffix

Version related suffix (or empty string if none is required).
E.g. '-9.2', part of e.g. default servicename, pg_engine, ...

=item exesuffix

Version related suffix for certain executables, like '92' in
'postgresql92-setup'.

=item defaultname

The default service name

=item servicename

The actual servicename

=item service

The C<NCM::Component::Postgresql::Service> instance

=item commands

The C<NCM::Component::Postgresql::Commands> instance

=back

Return hashref or undef on failure. No errors are logged

=cut

sub whoami
{
    my ($self, $config) = @_;

    my $iam = {};

    my $pg_engine = $self->fetch($config, "pg_engine", "/usr/bin/");

    $iam->{version} = $self->version($pg_engine);
    return if (! $iam->{version});

    $self->verbose("iam version ", join(' . ', @{$iam->{version}}), '.');

    my $pg_dir = $self->fetch($config, "pg_dir", $DEFAULT_BASEDIR);
    $iam->{pg} = {
        data => "$pg_dir/data",
        dir => $pg_dir,
        engine => $pg_engine,
        log => "$pg_dir/pgstartup.log",
        port => $self->fetch($config, "pg_port", $DEFAULT_PORT),
    };

    $self->verbose("iam pg dir $iam->{pg}->{dir} port $iam->{pg}->{port}",
                   " data $iam->{pg}->{data} log $iam->{pg}->{log}",
                   " engine $iam->{pg}->{engine}");

    my $pg_version = $self->fetch($config, "pg_version", "");
    my $pg_version_suf = $pg_version ? "-$pg_version" : "";
    $iam->{suffix} = $pg_version_suf;
    $self->verbose("iam suffix $iam->{suffix}");

    my $exesuffix_def = $pg_version;
    $exesuffix_def =~ s/\.//g;
    $iam->{exesuffix} = $self->fetch($config, "bin_version", $exesuffix_def);
    $self->verbose("iam exesuffix $iam->{exesuffix}");

    $iam->{defaultname} = "$POSTGRESQL$iam->{suffix}";
    $iam->{servicename} = $self->fetch($config, "pg_script_name", $iam->{defaultname});

    my $service = NCM::Component::Postgresql::Service->new(
        name => $iam->{servicename},
        log => $self,
        );

    if ($service) {
        $self->verbose("iam service instance created for name $iam->{servicename}");
        $iam->{service} = $service;
    } else {
        $self->warn("Failed to create service instance with name $iam->{servicename}");
        return;
    }

    $self->verbose("iam service $iam->{service}");

    $iam->{commands} = NCM::Component::Postgresql::Commands->new(
        $iam->{pg}->{engine},
        log => $self,
        );
    $self->verbose("iam commands added with engine $iam->{pg}->{engine}");

    return $iam;
}

=item sanity_check

Run some additional sanity checks, return undef on failure.

=cut

sub sanity_check
{
    my ($self, $iam) = @_;

    # some very nasty conditions once encountered
    $self->debug(1, "Starting some additional checks.");
    if ($self->_directory_exists($iam->{pg}->{data}) && (! $self->_file_exists("$iam->{pg}->{data}/PG_VERSION"))) {
        # ok, postgres will never like this
        # can't believe it will be running, but just to be certain
        $iam->{service}->status_stop();

        # non-destructive mode: make a backup
        my $moved_suffix = "-moved-for-postgres-by-ncm-postgresql." . strftime('%Y%m%d-%H%M%S', localtime());
        my $bck_data = "$iam->{pg}->{data}$moved_suffix";
        if ($CAF::Object::NoAction) {
            $self->info("NoAction: not moving $iam->{pg}->{data} to $bck_data.");
        } elsif (move($iam->{pg}->{data}, $bck_data)) {
            $self->warn("Moved $iam->{pg}->{data} to $bck_data.");
        } else {
            # it will never work, but next time make sure all goes well
            $self->error("Can't move $iam->{pg}->{data} to $bck_data. Please clean up.");
            return;
        }
    }

    return SUCCESS;
}

=item start_postgres

Try to start postgres service, the cautious way.

Return undef on failure, SUCCESS otherwise.

=cut

sub start_postgres
{

    my ($self, $config, $iam, $sysconfig_changed) = @_;

    # it's possible that PG_VERSION file doesn't yet exist (or even basedir PGDATA).
    # we assume this is only due to pre-init postgres
    if(! $self->_file_exists("$iam->{pg}->{data}/PG_VERSION")) {
        return if(! $self->initdb($iam));
        if(! $self->_file_exists("$iam->{pg}->{data}/PG_VERSION")) {
            $self->error("Succesful initdb but PG_VERSION still missing.");
            return;
        }
    }

    # only now we can generate the config files
    # PGDATA has to exist
    my $main_changed = $self->create_postgresql_config($config, $iam, %MAIN_CONFIG);
    return if (! defined($main_changed));

    my $hba_changed = $self->create_postgresql_config($config, $iam, %HBA_CONFIG);
    return if (! defined($hba_changed));

    # restart conditions first (because restart also reloads)
    if ($main_changed || $sysconfig_changed) {
        # most main params don't require a restart, but a few do.
        $self->info("main config or sysconfig changed, restarting");
        return if (! $iam->{service}->status_restart());
    } elsif ($hba_changed) {
        $self->info("hba config changed, reloading");
        return if (! $iam->{service}->status_reload());
    } else {
        $self->verbose("Nothing changed, nothing to do");
    }

    # start if not yet running
    return if (! $iam->{service}->status_start());

    return SUCCESS;
}


=item pg_alter

Process roles and databases. Returns undef on failure.

The main purpose is to initialise postgresql.

=cut

sub pg_alter
{
    my ($self, $config, $iam) = @_;

    my $roles_tree = $config->getTree($self->prefix."/roles");
    if (defined($roles_tree)) {
        return if(!defined($self->roles($config, $iam, $roles_tree)));
    } else {
        $self->verbose("No roles defined.");
    }

    my $dbs_tree = $config->getTree($self->prefix."/databases");
    if (defined($dbs_tree)) {
        return if(!defined($self->databases($iam, $dbs_tree)));
    } else {
        $self->verbose("No databases defined.");
    }

    return SUCCESS;
}


=item roles

C<$roles_tree> is the roles configuration hashref (via C<config->getTree(prefix/roles)>).

Roles and only added and modified, never removed.

Return undef on failure.

=cut

sub roles
{
    my ($self, $config, $iam, $roles_tree) = @_;

    # add any not-existing roles
    my $current_roles = $iam->{commands}->get_roles();
    return if (! defined($current_roles));

    foreach my $role (sort keys %$roles_tree) {
        if (grep {$_ eq $role} @$current_roles) {
            $self->verbose("Role $role already exists.");
            next;
        };
        $self->verbose("Creating role $role.");
        return if(! defined($iam->{commands}->create_role($role)));

        # Not assuming that the pg_alter file will be different,
        # e.g. component ran previously
        $self->verbose("Applying role attributes for new role $role.");
        return if(! defined($iam->{commands}->alter_role($role, $roles_tree->{$role})));
    }

    # make a copy of the Readonly hash
    my $pg_alter_data = {%PG_ALTER};
    $pg_alter_data->{FILENAME} = "pg_alter.ncm-postgresql";

    # data is key=role, value = md5sum of role SQL
    $pg_alter_data->{CONFIG_HASHREF} = { map {$_ => md5_hex($roles_tree->{$_})} keys %$roles_tree };

    my $changed = $self->create_postgresql_config($config, $iam, %$pg_alter_data);
    return if(! defined($changed));

    if($changed) {
        foreach my $role (sort keys %$roles_tree) {
            $self->verbose("(Re)applying role attributes for role $role.");
            return if(! defined($iam->{commands}->alter_role($role, $roles_tree->{$role})));
        }
    } else {
        $self->verbose('No roles changed');
    }

    return SUCCESS;
}

=item databases

C<$dbs_tree> is the databases configuration hashref (via C<config->getTree(prefix/databases)>).

Databases are only created, never modified or removed.

Return undef on failure.

Operation order is

=over

=item create database

=item initialise with installfile

=item create lang

=item apply langfile (if lang defined)

=back

=cut

sub databases
{
    my ($self, $iam, $dbs_tree) = @_;

    my $current_dbs = $iam->{commands}->get_databases();
    return if (! defined($current_dbs));

    foreach my $db_name (sort keys %$dbs_tree) {
        my $db = $dbs_tree->{$db_name};

        if (grep {$_ eq $db_name} @$current_dbs) {
            $self->verbose("Database $db_name already exists.");
            next;
        };

        # user is now mandatory, didn't used to be
        if(! $db->{user}) {
            $self->error("No user defined in profile for database $db_name.");
            return;
        }

        $self->info("Creating database $db_name and owner $db->{user}.");
        return if(! defined($iam->{commands}->create_database($db_name, $db->{user})));

        my $sql_user = $db->{sql_user} || $db->{user};

        if ($db->{installfile}) {
            $self->info("Initialising database $db_name with installfile $db->{installfile} as user $sql_user");
            return if(! defined($iam->{commands}->run_commands_from_file($db_name, $sql_user, $db->{installfile})));
        } else {
            $self->verbose("No installfile for database $db_name");
        }

        if ($db->{lang}) {
            $self->info("Creating lang $db->{lang} for database $db_name.");
            return if(! defined($iam->{commands}->create_database_lang($db_name, $db->{lang})));

            if ($db->{langfile}) {
                $self->info("Applying langfile $db->{langfile} to database $db_name as user $sql_user");
                return if(! defined($iam->{commands}->run_commands_from_file($db_name, $sql_user, $db->{langfile})));
            } else {
                $self->verbose("No langfile for database $db_name");
            }
        } else {
            $self->verbose("No lang for database $db_name");
        }

    }

    return SUCCESS;
}

=item Configure

component Configure method

=cut

sub Configure {
    my ($self, $config) = @_;

    my $iam = $self->whoami($config);
    if (! $iam) {
        $self->error('Failed to determine setup details. (See errors/warnings above).');
        return 0;
    };

    my $sysconfig_changed = $self->prepare_service($iam);
    return 0 if (! defined($sysconfig_changed));

    # now that prepare_service ran, we can start checking the service

    # get current state
    $self->verbose("Checking current status. Will be the same status after the component finishes.");
    my $current_status = $iam->{service}->status();
    $self->verbose("Current status: $current_status.");

    # this might remove PGDATA
    return 0 if (! defined($self->sanity_check($iam)));

    # try to (re)start postgres in state that is configured as intended
    return 0 if(! defined($self->start_postgres($config, $iam, $sysconfig_changed)));

    # so now we have a running postgres
    # make some more database configurations
    return 0 if (! defined($self->pg_alter($config, $iam)));

    # set postgres status to what it was
    my $method = "status_" . ($current_status ? "start" : "stop");
    $self->verbose("Setting status to what it was before the component ran:",
                   " $current_status using $method.");
    return 0 if (! defined($iam->{service}->$method()));

    return 1;
}

=pod

=back

=head2 Private methods

=over

=item _file_exists

Test if file exists

=cut

# TODO: move to CAF
sub _file_exists
{
    my ($self, $filename) = @_;
    return (-l $filename || -f $filename);
}

=item _directory_exists

Test if directory exists

=cut

# TODO: move to CAF
sub _directory_exists
{
    my ($self, $directory) = @_;
    return -d $directory;
}


=pod

=back

=cut

1;
