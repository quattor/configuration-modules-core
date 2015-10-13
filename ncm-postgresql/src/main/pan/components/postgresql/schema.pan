# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/postgresql/schema;

include 'quattor/types/component';

function pgsql_is_hba_db = {
    # Check cardinality and type of argument.
    if (ARGC != 1 || !is_string(ARGV[0]))
        error("usage: is_asndate(string)");

    if (match(ARGV[0], "all|sameuser|samerole|replication")) {
        return(true);
    } else {
        return(exists("/software/components/postgresql/databases/" + ARGV[0]));
    };
};

function pgsql_is_hba_address = {
    # Check cardinality and type of argument.
    if (ARGC != 1 || !is_string(ARGV[0]))
        error("usage: is_asndate(string)");

    if (match(ARGV[0],"samehost|samenet")) {
        return(true);
    } else {
        # It can be a host name, or it is made up of an IP address and a CIDR mask that is
        # an integer (between 0 and 32 (IPv4) or 128 (IPv6) inclusive) that
        # specifies the number of significant bits in the mask.  A host name
        # that starts with a dot (.) matches a suffix of the actual host name.
        # Alternatively, you can write an IP address and netmask in separate
        # columns to specify the set of hosts.
        
        ## TODO!
        return(true);
    }
};


type pgsql_hba_database = string with pgsql_is_hba_db(SELF);
type pgsql_hba_user = string with match(SELF,'^(\+|@)?\w+$');


type pgsql_hba = {
    "host"  : string with match(SELF, "^(local|host|hostssl|hostnossl)$")
    "database" : pgsql_hba_database[]
    "user" : pgsql_hba_user[]
    "address" ? string with pgsql_is_hba_address(SELF)
    "method" : string with match(SELF, "^(trust|reject|md5|password|gss|sspi|krb5|ident|peer|pam|ldap|radius|cert)$")
    "options" ? string{}
};


# generated with config2schema
# - changed listen_addresses to list
type pgsql_mainconfig = {
    "data_directory"                     ? string     # "ConfigDir"
    "hba_file"                           ? string     # "ConfigDir/pg_hba.conf"
    "ident_file"                         ? string     # "ConfigDir/pg_ident.conf"
    "external_pid_file"                  ? string     # "(none)"
    "listen_addresses"                   ? string[]   # "localhost"
    "port"                               ? long       # 5432
    "max_connections"                    ? long       # 100
    "superuser_reserved_connections"     ? long       # 3
    "unix_socket_directory"              ? string     # ""
    "unix_socket_group"                  ? string     # ""
    "unix_socket_permissions"            ? long       # 777
    "bonjour"                            ? boolean    # false
    "bonjour_name"                       ? string     # ""
    "authentication_timeout"             ? string     # 1min
    "ssl"                                ? boolean    # false
    "ssl_ciphers"                        ? string     # "ALL:!ADH:!LOW:!EXP:!MD5:@STRENGTH"
    "ssl_renegotiation_limit"            ? string     # 512MB
    "password_encryption"                ? boolean    # true
    "db_user_namespace"                  ? boolean    # false
    "krb_server_keyfile"                 ? string     # ""
    "krb_srvname"                        ? string     # "postgres"
    "krb_caseins_users"                  ? boolean    # false
    "tcp_keepalives_idle"                ? long       # 0
    "tcp_keepalives_interval"            ? long       # 0
    "tcp_keepalives_count"               ? long       # 0
    "shared_buffers"                     ? string     # 32MB
    "temp_buffers"                       ? string     # 8MB
    "max_prepared_transactions"          ? long       # 0
    "work_mem"                           ? string     # 1MB
    "maintenance_work_mem"               ? string     # 16MB
    "max_stack_depth"                    ? string     # 2MB
    "max_files_per_process"              ? long       # 1000
    "shared_preload_libraries"           ? string     # ""
    "vacuum_cost_delay"                  ? string     # 0ms
    "vacuum_cost_page_hit"               ? long       # 1
    "vacuum_cost_page_miss"              ? long       # 10
    "vacuum_cost_page_dirty"             ? long       # 20
    "vacuum_cost_limit"                  ? long       # 200
    "bgwriter_delay"                     ? string     # 200ms
    "bgwriter_lru_maxpages"              ? long       # 100
    "bgwriter_lru_multiplier"            ? string     # 2.0
    "effective_io_concurrency"           ? long       # 1
    "wal_level"                          ? string     # minimal
    "fsync"                              ? boolean    # true
    "synchronous_commit"                 ? boolean    # true
    "wal_sync_method"                    ? string     # fsync
    "full_page_writes"                   ? boolean    # true
    "wal_buffers"                        ? long       # -1
    "wal_writer_delay"                   ? string     # 200ms
    "commit_delay"                       ? long       # 0
    "commit_siblings"                    ? long       # 5
    "checkpoint_segments"                ? long       # 3
    "checkpoint_timeout"                 ? string     # 5min
    "checkpoint_completion_target"       ? string     # 0.5
    "checkpoint_warning"                 ? string     # 30s
    "archive_mode"                       ? boolean    # false
    "archive_command"                    ? string     # ""
    "archive_timeout"                    ? long       # 0
    "max_wal_senders"                    ? long       # 0
    "wal_sender_delay"                   ? string     # 1s
    "wal_keep_segments"                  ? long       # 0
    "vacuum_defer_cleanup_age"           ? long       # 0
    "replication_timeout"                ? string     # 60s
    "synchronous_standby_names"          ? string     # ""
    "hot_standby"                        ? boolean    # false
    "max_standby_archive_delay"          ? string     # 30s
    "max_standby_streaming_delay"        ? string     # 30s
    "wal_receiver_status_interval"       ? string     # 10s
    "hot_standby_feedback"               ? boolean    # false
    "enable_bitmapscan"                  ? boolean    # true
    "enable_hashagg"                     ? boolean    # true
    "enable_hashjoin"                    ? boolean    # true
    "enable_indexscan"                   ? boolean    # true
    "enable_material"                    ? boolean    # true
    "enable_mergejoin"                   ? boolean    # true
    "enable_nestloop"                    ? boolean    # true
    "enable_seqscan"                     ? boolean    # true
    "enable_sort"                        ? boolean    # true
    "enable_tidscan"                     ? boolean    # true
    "seq_page_cost"                      ? string     # 1.0
    "random_page_cost"                   ? string     # 4.0
    "cpu_tuple_cost"                     ? string     # 0.01
    "cpu_index_tuple_cost"               ? string     # 0.005
    "cpu_operator_cost"                  ? string     # 0.0025
    "effective_cache_size"               ? string     # 128MB
    "geqo"                               ? boolean    # true
    "geqo_threshold"                     ? long       # 12
    "geqo_effort"                        ? long       # 5
    "geqo_pool_size"                     ? long       # 0
    "geqo_generations"                   ? long       # 0
    "geqo_selection_bias"                ? string     # 2.0
    "geqo_seed"                          ? string     # 0.0
    "default_statistics_target"          ? long       # 100
    "constraint_exclusion"               ? string     # partition
    "cursor_tuple_fraction"              ? string     # 0.1
    "from_collapse_limit"                ? long       # 8
    "join_collapse_limit"                ? long       # 8
    "log_destination"                    : string     = "stderr"
    "logging_collector"                  : boolean    = true
    "log_directory"                      : string     = "pg_log"
    "log_filename"                       : string     = "postgresql-%a.log"
    "log_file_mode"                      ? long       # 600
    "log_truncate_on_rotation"           : boolean    = true
    "log_rotation_age"                   : string     = "1d"
    "log_rotation_size"                  : long       = 0
    "syslog_facility"                    ? string     # "LOCAL0"
    "syslog_ident"                       ? string     # "postgres"
    "silent_mode"                        ? boolean    # false
    "client_min_messages"                ? string     # notice
    "log_min_messages"                   ? string     # warning
    "log_min_error_statement"            ? string     # error
    "log_min_duration_statement"         ? long       # -1
    "debug_print_parse"                  ? boolean    # false
    "debug_print_rewritten"              ? boolean    # false
    "debug_print_plan"                   ? boolean    # false
    "debug_pretty_print"                 ? boolean    # true
    "log_checkpoints"                    ? boolean    # false
    "log_connections"                    ? boolean    # false
    "log_disconnections"                 ? boolean    # false
    "log_duration"                       ? boolean    # false
    "log_error_verbosity"                ? string     # default
    "log_hostname"                       ? boolean    # false
    "log_line_prefix"                    ? string     # ""
    "log_lock_waits"                     ? boolean    # false
    "log_statement"                      ? string     # "none"
    "log_temp_files"                     ? long       # -1
    "log_timezone"                       ? string     # "(defaults to server environment setting)"
    "track_activities"                   ? boolean    # true
    "track_counts"                       ? boolean    # true
    "track_functions"                    ? string     # none
    "track_activity_query_size"          ? long       # 1024
    "update_process_title"               ? boolean    # true
    "stats_temp_directory"               ? string     # "pg_stat_tmp"
    "log_parser_stats"                   ? boolean    # false
    "log_planner_stats"                  ? boolean    # false
    "log_executor_stats"                 ? boolean    # false
    "log_statement_stats"                ? boolean    # false
    "autovacuum"                         ? boolean    # true
    "log_autovacuum_min_duration"        ? long       # -1
    "autovacuum_max_workers"             ? long       # 3
    "autovacuum_naptime"                 ? string     # 1min
    "autovacuum_vacuum_threshold"        ? long       # 50
    "autovacuum_analyze_threshold"       ? long       # 50
    "autovacuum_vacuum_scale_factor"     ? string     # 0.2
    "autovacuum_analyze_scale_factor"    ? string     # 0.1
    "autovacuum_freeze_max_age"          ? long       # 200000000
    "autovacuum_vacuum_cost_delay"       ? string     # 20ms
    "autovacuum_vacuum_cost_limit"       ? long       # -1
    "search_path"                        ? string     # ""$user",public"
    "default_tablespace"                 ? string     # ""
    "temp_tablespaces"                   ? string     # ""
    "check_function_bodies"              ? boolean    # true
    "default_transaction_isolation"      ? string     # "read committed"
    "default_transaction_read_only"      ? boolean    # false
    "default_transaction_deferrable"     ? boolean    # false
    "session_replication_role"           ? string     # "origin"
    "statement_timeout"                  ? long       # 0
    "vacuum_freeze_min_age"              ? long       # 50000000
    "vacuum_freeze_table_age"            ? long       # 150000000
    "bytea_output"                       ? string     # "hex"
    "xmlbinary"                          ? string     # "base64"
    "xmloption"                          ? string     # "content"
    "datestyle"                          ? string     # "iso, mdy"
    "intervalstyle"                      ? string     # "postgres"
    "timezone"                           ? string     # "(defaults to server environment setting)"
    "timezone_abbreviations"             ? string     # "Default"
    "extra_float_digits"                 ? long       # 0
    "client_encoding"                    ? string     # sql_ascii
    "lc_messages"                        ? string     # "C"
    "lc_monetary"                        ? string     # "C"
    "lc_numeric"                         ? string     # "C"
    "lc_time"                            ? string     # "C"
    "default_text_search_config"         ? string     # "pg_catalog.simple"
    "dynamic_library_path"               ? string     # "$libdir"
    "local_preload_libraries"            ? string     # ""
    "deadlock_timeout"                   ? string     # 1s
    "max_locks_per_transaction"          ? long       # 64
    "max_pred_locks_per_transaction"     ? long       # 64
    "array_nulls"                        ? boolean    # true
    "backslash_quote"                    ? string     # safe_encoding
    "default_with_oids"                  ? boolean    # false
    "escape_string_warning"              ? boolean    # true
    "lo_compat_privileges"               ? boolean    # false
    "quote_all_identifiers"              ? boolean    # false
    "sql_inheritance"                    ? boolean    # true
    "standard_conforming_strings"        ? boolean    # true
    "synchronize_seqscans"               ? boolean    # true
    "transform_null_equals"              ? boolean    # false
    "exit_on_error"                      ? boolean    # false
    "restart_after_crash"                ? boolean    # true
    "custom_variable_classes"            ? string     # ""
};

type pg_db = {
	"user" ? string
	"installfile" ? string
	"sql_user" ? string
	"lang" ? string
	"langfile" ? string
};

type structure_pgsql_comp_config = {
	"debug_print" ? long 
	"hba" ? pgsql_hba[]
	"main" ? pgsql_mainconfig
};

type component_pgsql = {
    include structure_component
	include structure_component_dependency

	"pg_script_name" ? string
	"pg_dir" ? string
	"pg_port" ? string
	"postgresql_conf" ? string
	"pg_hba" ? string
	"roles" ? string{}
	"databases" ? pg_db{}
	"commands" ? string{}
	"config" ? structure_pgsql_comp_config
	"pg_version" ? string
	"pg_engine" ? string
};

bind "/software/components/postgresql" = component_pgsql;
