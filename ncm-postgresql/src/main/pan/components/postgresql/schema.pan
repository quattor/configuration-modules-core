# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/postgresql/schema;

include 'quattor/types/component';

function postgresql_is_hba_db = {
    # Check cardinality and type of argument.
    if (ARGC != 1 || !is_string(ARGV[0]))
        error(format("usage: %s(string)", FUNCTION));

    if (match(ARGV[0], "^(all|sameuser|samerole|replication)$")) {
        true;
    } else {
        exists("/software/components/postgresql/databases/" + ARGV[0]);
    };
};

function postgresql_is_hba_address = {
    # Check cardinality and type of argument.
    if (ARGC != 1 || !is_string(ARGV[0]))
        error(format("usage: %s(string)", FUNCTION));

    if (match(ARGV[0], "^(samehost|samenet)$")) {
        true;
    } else {
        # It can be a host name, or it is made up of an IP address and a CIDR mask that is
        # an integer (between 0 and 32 (IPv4) or 128 (IPv6) inclusive) that
        # specifies the number of significant bits in the mask.  A host name
        # that starts with a dot (.) matches a suffix of the actual host name.
        # Alternatively, you can write an IP address and netmask in separate
        # columns to specify the set of hosts.

        # TODO!
        true;
    }
};


type postgresql_hba_database = string with postgresql_is_hba_db(SELF);
type postgresql_hba_user = string with match(SELF, '^(\+|@)?\w+$');


type postgresql_hba = {
    "host" : string with match(SELF, "^(local|host((no)?ssl)?)$")
    "database" : postgresql_hba_database[]
    "user" : postgresql_hba_user[]
    "address" ? string with postgresql_is_hba_address(SELF)
    "method" : string with match(SELF, "^(trust|reject|md5|password|gss|sspi|krb5|ident|peer|pam|ldap|radius|cert)$")
    "options" ? string{}
};


# generated with config2schema
# - changed listen_addresses to list
@documentation{
    postgresql main configuration
        boolean -> yes / no
        int     -> int
        string  -> 'string' (use double single quotes for a single quote in the string)
}
type postgresql_mainconfig = {
    "archive_command" ? string     # ""
    "archive_mode" ? boolean    # false
    "archive_timeout" ? long       # 0
    "array_nulls" ? boolean    # true
    "authentication_timeout" ? string     # 1min
    "autovacuum" ? boolean    # true
    "autovacuum_analyze_scale_factor" ? string     # 0.1
    "autovacuum_analyze_threshold" ? long       # 50
    "autovacuum_freeze_max_age" ? long       # 200000000
    "autovacuum_max_workers" ? long       # 3
    "autovacuum_naptime" ? string     # 1min
    "autovacuum_vacuum_cost_delay" ? string     # 20ms
    "autovacuum_vacuum_cost_limit" ? long       # -1
    "autovacuum_vacuum_scale_factor" ? string     # 0.2
    "autovacuum_vacuum_threshold" ? long       # 50
    "backslash_quote" ? string     # safe_encoding
    "bgwriter_delay" ? string     # 200ms
    "bgwriter_lru_maxpages" ? long       # 100
    "bgwriter_lru_multiplier" ? string     # 2.0
    "bonjour" ? boolean    # false
    "bonjour_name" ? string     # ""
    "bytea_output" ? string     # "hex"
    "check_function_bodies" ? boolean    # true
    "checkpoint_completion_target" ? string     # 0.5
    "checkpoint_segments" ? long with {
        deprecated(0, 'checkpoint_segments is deprecated since Postgres version 9.5.');
        true;
    } # 3
    "checkpoint_timeout" ? string     # 5min
    "checkpoint_warning" ? string     # 30s
    "client_encoding" ? string     # sql_ascii
    "client_min_messages" ? string     # notice
    "commit_delay" ? long       # 0
    "commit_siblings" ? long       # 5
    "constraint_exclusion" ? string     # partition
    "cpu_index_tuple_cost" ? string     # 0.005
    "cpu_operator_cost" ? string     # 0.0025
    "cpu_tuple_cost" ? string     # 0.01
    "cursor_tuple_fraction" ? string     # 0.1
    "custom_variable_classes" ? string     # ""
    "data_directory" ? string     # "ConfigDir"
    "datestyle" ? string     # "iso, mdy"
    "db_user_namespace" ? boolean    # false
    "deadlock_timeout" ? string     # 1s
    "debug_pretty_print" ? boolean    # true
    "debug_print_parse" ? boolean    # false
    "debug_print_plan" ? boolean    # false
    "debug_print_rewritten" ? boolean    # false
    "default_statistics_target" ? long       # 100
    "default_tablespace" ? string     # ""
    "default_text_search_config" ? string     # "pg_catalog.simple"
    "default_transaction_deferrable" ? boolean    # false
    "default_transaction_isolation" ? string     # "read committed"
    "default_transaction_read_only" ? boolean    # false
    "default_with_oids" ? boolean    # false
    "dynamic_library_path" ? string     # "$libdir"
    "effective_cache_size" ? string     # 128MB
    "effective_io_concurrency" ? long       # 1
    "enable_bitmapscan" ? boolean    # true
    "enable_hashagg" ? boolean    # true
    "enable_hashjoin" ? boolean    # true
    "enable_indexscan" ? boolean    # true
    "enable_material" ? boolean    # true
    "enable_mergejoin" ? boolean    # true
    "enable_nestloop" ? boolean    # true
    "enable_seqscan" ? boolean    # true
    "enable_sort" ? boolean    # true
    "enable_tidscan" ? boolean    # true
    "escape_string_warning" ? boolean    # true
    "exit_on_error" ? boolean    # false
    "external_pid_file" ? string     # "(none)"
    "extra_float_digits" ? long       # 0
    "from_collapse_limit" ? long       # 8
    "fsync" ? boolean    # true
    "full_page_writes" ? boolean    # true
    "geqo" ? boolean    # true
    "geqo_effort" ? long       # 5
    "geqo_generations" ? long       # 0
    "geqo_pool_size" ? long       # 0
    "geqo_seed" ? string     # 0.0
    "geqo_selection_bias" ? string     # 2.0
    "geqo_threshold" ? long       # 12
    "hba_file" ? string     # "ConfigDir/pg_hba.conf"
    "hot_standby" ? boolean    # false
    "hot_standby_feedback" ? boolean    # false
    "ident_file" ? string     # "ConfigDir/pg_ident.conf"
    "intervalstyle" ? string     # "postgres"
    "join_collapse_limit" ? long       # 8
    "krb_caseins_users" ? boolean    # false
    "krb_server_keyfile" ? string     # ""
    "krb_srvname" ? string     # "postgres"
    "lc_messages" ? string     # "C"
    "lc_monetary" ? string     # "C"
    "lc_numeric" ? string     # "C"
    "lc_time" ? string     # "C"
    "listen_addresses" ? string[]   # "localhost"
    "lo_compat_privileges" ? boolean    # false
    "local_preload_libraries" ? string     # ""
    "log_autovacuum_min_duration" ? long       # -1
    "log_checkpoints" ? boolean    # false
    "log_connections" ? boolean    # false
    "log_destination" : string     = "stderr"
    "log_directory" : string     = "pg_log"
    "log_disconnections" ? boolean    # false
    "log_duration" ? boolean    # false
    "log_error_verbosity" ? string     # default
    "log_executor_stats" ? boolean    # false
    "log_file_mode" ? long       # 600
    "log_filename" : string     = "postgresql-%a.log"
    "log_hostname" ? boolean    # false
    "log_line_prefix" ? string     # ""
    "log_lock_waits" ? boolean    # false
    "log_min_duration_statement" ? long       # -1
    "log_min_error_statement" ? string     # error
    "log_min_messages" ? string     # warning
    "log_parser_stats" ? boolean    # false
    "log_planner_stats" ? boolean    # false
    "log_rotation_age" : string     = "1d"
    "log_rotation_size" : long       = 0
    "log_statement" ? string     # "none"
    "log_statement_stats" ? boolean    # false
    "log_temp_files" ? long       # -1
    "log_timezone" ? string     # "(defaults to server environment setting)"
    "log_truncate_on_rotation" : boolean    = true
    "logging_collector" : boolean    = true
    "maintenance_work_mem" ? string     # 16MB
    "max_connections" ? long       # 100
    "max_files_per_process" ? long       # 1000
    "max_locks_per_transaction" ? long       # 64
    "max_pred_locks_per_transaction" ? long       # 64
    "max_prepared_transactions" ? long       # 0
    "max_stack_depth" ? string     # 2MB
    "max_standby_archive_delay" ? string     # 30s
    "max_standby_streaming_delay" ? string     # 30s
    "max_wal_senders" ? long       # 0
    "password_encryption" ? boolean    # true
    "port" ? long       # 5432
    "quote_all_identifiers" ? boolean    # false
    "random_page_cost" ? string     # 4.0
    "replication_timeout" ? string     # 60s
    "restart_after_crash" ? boolean    # true
    "search_path" ? string     # ""$user",public"
    "seq_page_cost" ? string     # 1.0
    "session_replication_role" ? string     # "origin"
    "shared_buffers" ? string     # 32MB
    "shared_preload_libraries" ? string     # ""
    "silent_mode" ? boolean    # false
    "sql_inheritance" ? boolean    # true
    "ssl" ? boolean    # false
    "ssl_ciphers" ? string     # "ALL:!ADH:!LOW:!EXP:!MD5:@STRENGTH"
    "ssl_renegotiation_limit" ? string     # 512MB
    "standard_conforming_strings" ? boolean    # true
    "statement_timeout" ? long       # 0
    "stats_temp_directory" ? string     # "pg_stat_tmp"
    "superuser_reserved_connections" ? long       # 3
    "synchronize_seqscans" ? boolean    # true
    "synchronous_commit" ? boolean    # true
    "synchronous_standby_names" ? string     # ""
    "syslog_facility" ? string     # "LOCAL0"
    "syslog_ident" ? string     # "postgres"
    "tcp_keepalives_count" ? long       # 0
    "tcp_keepalives_idle" ? long       # 0
    "tcp_keepalives_interval" ? long       # 0
    "temp_buffers" ? string     # 8MB
    "temp_tablespaces" ? string     # ""
    "timezone" ? string     # "(defaults to server environment setting)"
    "timezone_abbreviations" ? string     # "Default"
    "track_activities" ? boolean    # true
    "track_activity_query_size" ? long       # 1024
    "track_counts" ? boolean    # true
    "track_functions" ? string     # none
    "transform_null_equals" ? boolean    # false
    "unix_socket_directory" ? string     # ""
    "unix_socket_group" ? string     # ""
    "unix_socket_permissions" ? long       # 777
    "update_process_title" ? boolean    # true
    "vacuum_cost_delay" ? string     # 0ms
    "vacuum_cost_limit" ? long       # 200
    "vacuum_cost_page_dirty" ? long       # 20
    "vacuum_cost_page_hit" ? long       # 1
    "vacuum_cost_page_miss" ? long       # 10
    "vacuum_defer_cleanup_age" ? long       # 0
    "vacuum_freeze_min_age" ? long       # 50000000
    "vacuum_freeze_table_age" ? long       # 150000000
    "wal_buffers" ? long       # -1
    "wal_keep_segments" ? long       # 0
    "wal_level" ? string     # minimal
    "wal_receiver_status_interval" ? string     # 10s
    "wal_sender_delay" ? string     # 1s
    "wal_sync_method" ? string     # fsync
    "wal_writer_delay" ? string     # 200ms
    "work_mem" ? string     # 1MB
    "xmlbinary" ? string     # "base64"
    "xmloption" ? string     # "content"
};

type postgresql_db = {
    @{this file is used to initialise the database (using the pgsql -f option)}
    "installfile" ? string
    @{sets the pg language for the db (using createlang), this runs after installfile. }
    "lang" ? string
    @{this file is used to add procedures in certain lang (using pgsql -f option), this runs after successful lang is added}
    "langfile" ? string
    @{apply the installfile with this user (if not defined, the owner is used)}
    "sql_user" ? string
    @{database owner}
    "user" : string
};

type postgresql_config = {
    "hba" ? postgresql_hba[]
    "main" ? postgresql_mainconfig
    "debug_print" ? long with {
        deprecated(0, 'postgresql debug_print is not used anymore');
        true;
    } # deprecated/unused
};

@documentation{
    The raw ALTER ROLE sql (cannot contain a ';'; use ENCRYPTED PASSWORD instead)
}
type postgresql_role_sql = string with {
    if(match(SELF, ';')) {
        error('The role sql data cannot contain a ";" (use ENCRYPTED PASSWORD if your password has ";")');
    };
    # TODO: Force ENCRYPTED PASSWORD usage?

    true;
};

type component_postgresql = {
    include structure_component
    include structure_component_dependency

    "commands" ? string{} with {
        deprecated(0, 'commands is unsupported');
        true;
    } # also in old version of the component
    "config" ? postgresql_config
    @{Databases are only added/created, never updated, modified or removed.}
    "databases" ? postgresql_db{}
    "pg_dir" ? string
    "pg_engine" ? string
    "pg_hba" ? string
    "pg_port" ? string with match(SELF, '^\d+$')
    "pg_script_name" ? string # the name of service to use
    "pg_version" ? string
    "postgresql_conf" ? string
    @{role name with ROLE ALTER SQL command. Roles are only added and updated, never removed.}
    "roles" ? postgresql_role_sql{}
} with {
    # handle legacy schema problems with port defined in 2 locations
    pg_port = -1;
    if (exists(SELF["pg_port"])) {
        pg_port = to_long(SELF["pg_port"]);
    };
    port = -1;

    if (exists(SELF["config"]["main"]["port"])) {
        port = SELF["config"]["main"]["port"];
    };

    if (exists(SELF["config"]) && (pg_port != port)) {
        error(format("Legacy pg_port %s and config/main/port %s must be the same", pg_port, port));
    };

    true;
};
