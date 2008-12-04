# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/php/schema;

include pan/structures;

    
############################################################
# PHP config
############################################################



type php_boolval = long(0..1);
type php_boolstr = string with match(self, "^(true|false)$");
type php_onoffstr = string with match(self, "^(On|Off)$");
type php_quotedstr = string with match(self, '".*"');
type php_colorstr = string with match(self, "^#[0-9a-zA-Z]{6}$");
type php_quotedtagstr = string with match(self, '^"<.*>"$');
type php_mbstr = string with match(self, '^\d+(M|B)?$');
type php_dirstr = string with match(self, '^[\w/]*$');
type php_quotedmailstr = string with match(self, '".*@.*"');

type structure_php_all_type = {
    "name" ?    string
    "prep_name" ?    string
};


type structure_php_zlib = {

    include structure_php_all_type
    "output_compression" ?    string
    "output_handler" ?    long

};
    
type structure_php_argsep = {

    include structure_php_all_type

    "output" ? php_quotedstr
    "input"  ? php_quotedstr

};
    

type structure_php_highlight = {

    include structure_php_all_type
    "string"  ?    php_colorstr
    "comment" ?    php_colorstr
    "keyword" ?    php_colorstr
    "bg"      ?    php_colorstr
    "default" ?    php_colorstr
    "html"    ?    php_colorstr
};    



type structure_php_cgi = {

    include structure_php_all_type
    "rfc2616_headers" ?    php_boolval

};    


# [PHP]
type structure_php_main = {

    include structure_php_all_type
    
    "zlib" ?    structure_php_zlib
    "highlight" ?    structure_php_highlight
    "cgi" ?    structure_php_cgi
    "argsep" ?    structure_php_argsep

    "engine" ?    php_onoffstr
    "short_open_tag" ?    php_onoffstr
    "asp_tags" ?    php_onoffstr
    "precision"    ?    long
    "y2k_compliance" ?    php_onoffstr
    "output_buffering" ?    string
    "implicit_flush" ?    php_onoffstr
    "unserialize_callback_func"?    string
    "serialize_precision" ?    long
    "allow_call_time_pass_reference" ?    php_onoffstr
    "safe_mode" ?    php_onoffstr
    "safe_mode_gid" ?    php_onoffstr
    "safe_mode_include_dir" ?    php_dirstr
    "safe_mode_exec_dir" ?    php_dirstr
    "safe_mode_allowed_env_vars" ?    string
    "safe_mode_protected_env_vars" ?    string
    "open_basedir" ?    php_dirstr
    "disable_functions" ?    string
    "disable_classes" ?    string
    "expose_php" ?    php_onoffstr
    "max_execution_time" ? long
    "max_input_time" ? long
    "memory_limit" ? string
    "error_reporting" ?    string
    "display_errors" ?    php_onoffstr
    "display_startup_errors" ?    php_onoffstr
    "log_errors" ?    php_onoffstr
    "log_errors_max_len" ?    long
    "ignore_repeated_errors" ?    php_onoffstr
    "ignore_repeated_source" ?    php_onoffstr
    "report_memleaks" ?    php_onoffstr
    "track_errors" ?    php_onoffstr
    "html_errors" ?    php_onoffstr
    "docref_root" ?    string
    "docref_ext" ?    string
    "error_prepend_string" ?   php_quotedtagstr 
    "error_append_string" ?    php_quotedtagstr
    "error_log" ?    string
    "variables_order" ?    php_quotedstr
    "register_globals" ?    php_onoffstr
    "register_argc_argv" ?    php_onoffstr
    "post_max_size" ?    php_mbstr
    "gpc_order" ?    php_quotedstr
    "magic_quotes_gpc" ?    php_onoffstr
    "magic_quotes_runtime" ?    php_onoffstr
    "magic_quotes_sybase" ?    php_onoffstr
    "auto_prepend_file" ?    string
    "auto_append_file" ?    string
    "default_mimetype" ?    php_quotedstr
    "default_charset" ?    php_quotedstr
    "always_populate_raw_post_data" ?    php_onoffstr
    "include_path" ?    php_quotedstr
    "doc_root" ?    php_dirstr
    "user_dir" ?    php_dirstr
    "extension_dir" ?    php_dirstr
    "enable_dl" ?    php_onoffstr
    "file_uploads" ?    php_onoffstr
    "upload_tmp_dir" ?    php_dirstr
    "upload_max_filesize" ?    php_mbstr
    "allow_url_fopen" ?    string
    "from" ?    php_quotedmailstr
    "user_agent"?    php_quotedstr
    "default_socket_timeout" ?    long

};    

# [Syslog]
type structure_php_syslog = {

    include structure_php_all_type
    "define_syslog_variables"  ?    string

};    


# [mail function]
type structure_php_mailfunct = {

    include structure_php_all_type
    "SMTP" ?    string
    "smtp_port" ?    long
    "sendmail_path" ? string

};    


type structure_php_class = {

    include structure_php_all_type
    "path" ? string

};    


# [Java]
type structure_php_java = {

    include structure_php_all_type
    "class" ?    string
    "home"  ?    string
    "library"  ?    string

};

# [SQL]
type structure_php_sql = {

    include structure_php_all_type
    "safe_mode" ?    php_onoffstr

};    


# [OBDC]
type structure_php_odbc = {

    include structure_php_all_type
    "default_db"    ? string
    "default_user"  ? string
    "default_pw"    ? string
    "allow_persistent" ?    php_onoffstr
    "check_persistent" ?    php_onoffstr
    "max_persistent" ?    long
    "max_links" ?    long
    "defaultlrl" ?    long
    "defaultbinmode" ?    long

};


# [MySQL]
type structure_php_mysql = {

    include structure_php_all_type
    "allow_persistent" ?    php_onoffstr
    "max_persistent" ?    long
    "max_links" ?    long
    "default_port" ?    long
    "default_socket" ?    long
    "default_host" ?    string
    "default_user" ?    string
    "default_password" ?    string
    "connect_timeout" ?    long
    "trace_mode" ?    php_onoffstr

};    
 

# [mSQL]
type structure_php_msql = {

    include structure_php_all_type
    "allow_persistent" ?    php_onoffstr
    "max_persistent" ?    long
    "max_links" ?    long

};    


# [PostgresSQL]
type structure_php_pgsql = {

    include structure_php_all_type
    "allow_persistent" ?    php_onoffstr
    "auto_reset_persistent" ?    php_onoffstr
    "max_persistent" ?    long
    "max_links" ?    long
    "ignore_notice" ?    long
    "log_notice" ?    long
    
};
    

# [Sybase]
type structure_php_sybase = {

    include structure_php_all_type
    "allow_persistent" ?    string
    "max_persistent" ?    long
    "max_links" ?    long
    "interface_file" ?    string
    "min_error_severity" ?    long
    "min_message_severity" ?    long
    "compatability_mode" ?    php_onoffstr
    
};


# [Sybase-CT]
type structure_php_sybct = {

    include structure_php_all_type
    "allow_persistent" ?    string
    "max_persistent" ?    long
    "max_links" ?    long
    "min_server_severity" ?    long
    "min_client_severity" ?    long

};    

# [dbx]
type structure_php_dbx = {

    include structure_php_all_type
    "colnames_case" ?    php_quotedstr

};


# [bcmath]
type structure_php_bcmath = {

    include structure_php_all_type
    "scale" ?    long

};    


# [browscap]
type structure_php_browscap = {

    include structure_php_all_type
    "browscap" ? string

};
    

# [Informix]
type structure_php_ifx = {

    include structure_php_all_type
    "default_host" ?    string
    "default_user" ?    string
    "default_password" ?    string
    "allow_persistent" ?    php_onoffstr
    "max_persistent" ?    long
    "max_links" ?    long
    "textasvarchar" ?    long
    "byteasvarchar" ?    long
    "charasvarchar" ?    long
    "blobinfile" ?    long
    "nullformat" ?    long
    
};


type structure_php_urlrw = {

    include structure_php_all_type
    "tags" ?    php_quotedstr

};

    
# [Session]
type structure_php_session = {

    include structure_php_all_type
    "save_handler" ?    string
    "save_path" ?    php_dirstr
    "use_cookies" ?    long
    "name" ?    string
    "auto_start" ?    long
    "cookie_lifetime" ?    long
    "cookie_path" ?    php_dirstr
    "cookie_domain" ?    string
    "serialize_handler" ?    string
    "gc_probability" ?    long
    "gc_divisor"     ?    long
    "gc_maxlifetime" ?    long
    "bug_compat_42" ?    long
    "bug_compat_warn" ?    long
    "referer_check" ?    long
    "entropy_length" ?    long
    "entropy_file" ?    string
    "cache_limiter" ?    string
    "cache_expire" ?    long
    "use_trans_sid" ?    long

    "url_rewriter"  ? structure_php_urlrw

};
    

# [MSSQL]
type structure_php_mssql = {

    include structure_php_all_type
    "allow_persistent" ?    php_onoffstr
    "max_persistent" ?    long
    "max_links" ?    long
    "min_error_severity" ?    long
    "min_message_severity" ?    long
    "compatability_mode" ?    php_onoffstr
    "connect_timeout" ?    long
    "timeout" ?    long
    "textlimit" ?    long
    "textsize" ?    long
    "batchsize" ?    long
    "datetimeconvert" ?    php_onoffstr
    "secure_connection" ?    php_onoffstr
    "max_procs" ?    long

};    
    

# [Assertion]
type structure_php_assert = {

    include structure_php_all_type
    "active" ?    php_onoffstr
    "warning" ?    php_onoffstr
    "bail" ?    php_onoffstr
    "callback" ?    long
    "quiet_eval" ?    long

};
    

# [Ingres II]
type structure_php_ingres = {

    include structure_php_all_type
    "allow_persistent" ?    php_onoffstr
    "max_persistent" ?    long
    "max_links" ?    long
    "default_database" ?    string
    "default_user" ?    string
    "default_password" ?    string

};
    

# [Verisign Payflow Pro]
type structure_php_pfpro = {

    include structure_php_all_type
    "defaulthost" ? string
    "defaultport" ?    long
    "defaulttimeout" ?    long
    "proxyaddress" ?    string
    "proxyport" ?    long
    "proxylogon" ?    string
    "proxypassword" ?    string

};
    

# [Sockets]
type structure_php_sockets = {

    include structure_php_all_type
    "use_system_read" ?    php_onoffstr

};
    

# [com]
type structure_php_com = {

    include structure_php_all_type
    "typelib_file" ?    string
    "allow_dcom" ?    php_boolstr
    "autoregister_typelib" ?    php_boolstr
    "autoregister_casesensitive" ?    php_boolstr
    "autoregister_verbose" ?    php_boolstr

};    


# [Printer]
type structure_php_printer = {

    include structure_php_all_type
    "default_printer" ?    php_quotedstr

};    

# [php_mbstring]
type structure_php_mbstring = {

    include structure_php_all_type
    "language" ?    string
    "internal_encoding" ?    string
    "http_input" ?    string
    "http_output" ?    string
    "encoding_translation" ?    php_onoffstr
    "detect_order" ?    string
    "substitute_character" ? string
    "func_overload" ?    long

};
    

# [FrontBase]
type structure_php_fbsql = {

    include structure_php_all_type
    "allow_persistent" ?    php_onoffstr
    "autocommit" ?    php_onoffstr
    "default_database" ?    string
    "default_database_password" ?    string
    "default_host" ?    string
    "default_password" ?    string
    "default_user"   ? php_quotedstr
    "generate_warnings" ?    php_onoffstr
    "max_connections" ?    long
    "max_links" ?    long
    "max_persistent" ?    long
    "max_results" ?    long
    "batchSize" ?    long

};    

# [Crack]
type structure_php_crack = {

    include structure_php_all_type
    "crack.default_dictionary" ?     php_quotedstr

};    

# [exif]
type structure_php_exif = {

    include structure_php_all_type
    "encode_unicode" ?    string
    "decode_unicode_motorola" ?    string
    "decode_unicode_intel"    ?    string
    "encode_jis" ?    string
    "decode_jis_motorola" ?    string
    "decode_jis_intel"    ?    string

};
    


type component_php_conf = {

    "main" :    structure_php_main
    "syslog" ?    structure_php_syslog
    "mailfunct" ?    structure_php_mailfunct
    "java" ?    structure_php_java
    "sql" ?    structure_php_sql
    "odbc" ?    structure_php_odbc
    "mysql" ?    structure_php_mysql
    "msql" ?    structure_php_msql
    "pgsql" ?    structure_php_pgsql
    "sybase" ?    structure_php_sybase
    "sybct" ?    structure_php_sybct
    "dbx" ?    structure_php_dbx
    "bcmath" ?    structure_php_bcmath
    "browscap" ?    structure_php_browscap
    "ifx" ?    structure_php_ifx
    "session" ?    structure_php_session
    "mssql" ?    structure_php_mssql
    "assert" ?    structure_php_assert
    "ingres" ?    structure_php_ingres
    "pfpro" ?    structure_php_pfpro
    "sockets" ?    structure_php_sockets
    "com" ?    structure_php_com
    "printer" ?    structure_php_printer
    "mbstring" ?    structure_php_mbstring
    "fbsql" ?    structure_php_fbsql
    "crack" ?    structure_php_crack
    "exif" ?    structure_php_exif

};

type component_php = {
   include component_type
   "conf"    :   component_php_conf
};


type "/software/components/php" = component_php;
    

