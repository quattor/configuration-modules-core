# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/postfix/schema;

include 'quattor/types/component';

@{
    Types of lookup tables (databases) Postfix is capable to handle.
}
type postfix_lookup_type_string = string with
    match (SELF, "^(btree|cdb|cidr|dbm|environ|fail|hash|internal|ldap" +
        "|memcache|mysql|netinfo|nis|nisplus|pcre|pgsql|proxy|regexp" +
        "|sdbm|socketmap|sqlite|static|tcp|texthash|unix)$") ||
    error ("Wrong Postfix lookup type. See http://www.postfix.org/DATABASE_README.html for details");

@{
    Definition of a lookup in Postfix
}
type postfix_lookup = {
    @{ The type of the database for this lookup }
    "type" : postfix_lookup_type_string
    @{ The name of the lookup (DB connection, file name...) }
    "name" : string
};

@{
    Description of a Postfix LDAP database. See
    http://www.postfix.org/ldap_table.5.html
}
type postfix_ldap_database = {
    "server_host" : type_fqdn[]
    "server_host_protocol" ? string with match(SELF, "^ldaps?$")
    "server_port" ? type_port
    "timeout" ? long
    "search_base" : string
    "query_filter" : string
    "result_format" : string
    "domain" ? type_fqdn
    "result_attribute" : string[] = list("maildrop")
    "special_result_attribute" ? string[]
    "terminal_result_attribute" ? string
    "leaf_result_attribute" ? string
    "scope" : string = "sub"
    "bind" : boolean
    "bind_dn" ? string
    "bind_pw" ? string
    "recursion_limit" ? long
    "expansion_limit" ? long
    "size_limit" ? long
    "dereference" ? long(0..3)
    "chase_referrals" ? long
    "version" : long = 2
    "debuglevel" : long = 0
    "start_tls" ? boolean
    "tls_ca_cert_dir" ? string
    "tls_ca_cert_file" ? string
    "tls_cert" ? string
    "tls_key" ? string
    "tls_require_cert" ? boolean
    "tls_random_file" ? string
    "tls_cipher_suite" ? string
};

final variable MINUTES = 60;
final variable HOURS = MINUTES * 60;
final variable DAYS = HOURS * 24;
final variable WEEKS = DAYS * 7;

@{
    All fields available in main.cf. Nothing is mandatory here, since
    it all has default values. Time limits are expressed in
    SECONDS. Multiply by the appropriate constant above to simplify
    your code.
}
type postfix_main = {
    "_2bounce_notice_recipient" ? string
    "access_map_reject_code" ? long
    "address_verify_default_transport" ? string
    "address_verify_local_transport" ? string
    "address_verify_map" ? string
    "address_verify_negative_cache" ? boolean
    "address_verify_negative_expire_time" ? long
    "address_verify_negative_refresh_time" ? long
    "address_verify_poll_count" ? long
    "address_verify_poll_delay" ? long
    "address_verify_positive_expire_time" ? long
    "address_verify_positive_refresh_time" ? long
    "address_verify_relay_transport" ? string
    "address_verify_relayhost" ? string
    "address_verify_sender" ? string
    "address_verify_sender_dependent_relayhost_maps" ? string
    "address_verify_service_name" ? string
    "address_verify_transport_maps" ? string
    "address_verify_virtual_transport" ? string
    "alias_database" ? postfix_lookup
    "alias_maps" ? postfix_lookup[]
    "allow_mail_to_commands" ? string[]
    "allow_mail_to_files" ? string[]
    "allow_min_user" ? boolean
    "allow_percent_hack" ? boolean
    "allow_untrusted_routing" ? boolean
    "alternate_config_directories" ? string
    "always_bcc" ? string
    "anvil_rate_time_unit" ? long
    "anvil_status_update_time" ? long
    "append_at_myorigin" ? boolean
    "append_dot_mydomain" ? boolean
    "application_event_drain_time" ? long
    "authorized_flush_users" ? postfix_lookup
    "authorized_mailq_users" ? postfix_lookup
    "authorized_submit_users" ? postfix_lookup
    "backwards_bounce_logfile_compatibility" ? boolean
    "berkeley_db_create_buffer_size" ? long
    "berkeley_db_read_buffer_size" ? long
    "best_mx_transport" ? string
    "biff" ? boolean
    "body_checks" ? string
    "body_checks_size_limit" ? long
    "bounce_notice_recipient" ? string
    "bounce_queue_lifetime" ? long
    "bounce_service_name" ? string
    "bounce_size_limit" ? long
    "bounce_template_file" ? string
    "broken_sasl_auth_clients" ? boolean
    "canonical_classes" ? string[]
    "canonical_maps" ? string
    "cleanup_service_name" ? string
    "command_directory" ? string
    "command_execution_directory" ? string
    "command_expansion_filter" ? string
    "command_time_limit" ? long
    "config_directory" ? string
    "connection_cache_protocol_timeout" ? long
    "connection_cache_service_name" ? string
    "connection_cache_status_update_time" ? long
    "connection_cache_ttl_limit" ? long
    "content_filter" ? string
    "daemon_directory" ? string
    "daemon_timeout" ? long
    "debug_peer_level" ? long
    "debug_peer_list" ? string
    "default_database_type" ? string
    "default_delivery_slot_cost" ? long
    "default_delivery_slot_discount" ? long
    "default_delivery_slot_loan" ? long
    "default_destination_concurrency_limit" ? long
    "default_destination_recipient_limit" ? long
    "default_extra_recipient_limit" ? long
    "default_minimum_delivery_slots" ? long
    "default_privs" ? string
    "default_process_limit" ? long
    "default_rbl_reply" ? string
    "default_recipient_limit" ? long
    "default_transport" ? string
    "default_verp_delimiters" ? string
    "defer_code" ? long
    "defer_service_name" ? string
    "defer_transports" ? string
    "delay_logging_resolution_limit" ? long
    "delay_notice_recipient" ? string
    "delay_warning_time" ? long
    "deliver_lock_attempts" ? long
    "deliver_lock_delay" ? long
    "disable_dns_lookups" ? boolean
    "disable_mime_input_processing" ? boolean
    "disable_mime_output_conversion" ? boolean
    "disable_verp_bounces" ? boolean
    "disable_vrfy_command" ? boolean
    "dont_remove" ? long
    "double_bounce_sender" ? string
    "duplicate_filter_limit" ? long
    "empty_address_recipient" ? string
    "enable_original_recipient" ? boolean
    "error_notice_recipient" ? string
    "error_service_name" ? string
    "execution_directory_expansion_filter" ? string
    "expand_owner_alias" ? boolean
    "export_environment" ? string
    "fallback_transport" ? string
    "fallback_transport_maps" ? string
    "fast_flush_domains" ? string
    "fast_flush_purge_time" ? long
    "fast_flush_refresh_time" ? long
    "fault_injection_code" ? long
    "flush_service_name" ? string
    "fork_attempts" ? long
    "fork_delay" ? long
    "forward_expansion_filter" ? string
    "forward_path" ? string[]
    "frozen_delivered_to" ? boolean
    "hash_queue_depth" ? long
    "hash_queue_names" ? string[]
    "header_address_token_limit" ? long
    "header_checks" ? string
    "header_size_limit" ? long
    "helpful_warnings" ? boolean
    "home_mailbox" ? string
    "hopcount_limit" ? long
    "html_directory" ? boolean
    "ignore_mx_lookup_error" ? boolean
    "import_environment" ? string
    "in_flow_delay" ? long
    "inet_interfaces" ? string[]
    "inet_protocols" ? string
    "initial_destination_concurrency" ? long
    "internal_mail_filter_classes" ? string
    "invalid_hostname_reject_code" ? long
    "ipc_idle" ? long
    "ipc_timeout" ? long
    "ipc_ttl" ? long
    "line_length_limit" ? long
    "lmtp_bind_address" ? string
    "lmtp_bind_address6" ? string
    "lmtp_cname_overrides_servername" ? boolean
    "lmtp_connect_timeout" ? long
    "lmtp_connection_cache_destinations" ? string
    "lmtp_connection_cache_on_demand" ? boolean
    "lmtp_connection_cache_time_limit" ? long
    "lmtp_connection_reuse_time_limit" ? long
    "lmtp_data_done_timeout" ? long
    "lmtp_data_init_timeout" ? long
    "lmtp_data_xfer_timeout" ? long
    "lmtp_defer_if_no_mx_address_found" ? boolean
    "lmtp_destination_concurrency_limit" ? string
    "lmtp_destination_recipient_limit" ? string
    "lmtp_discard_lhlo_keyword_address_maps" ? string
    "lmtp_discard_lhlo_keywords" ? string
    "lmtp_enforce_tls" ? boolean
    "lmtp_generic_maps" ? string
    "lmtp_host_lookup" ? string
    "lmtp_lhlo_name" ? string
    "lmtp_lhlo_timeout" ? long
    "lmtp_line_length_limit" ? long
    "lmtp_mail_timeout" ? long
    "lmtp_mx_address_limit" ? long
    "lmtp_mx_session_limit" ? long
    "lmtp_pix_workaround_delay_time" ? long
    "lmtp_pix_workaround_threshold_time" ? long
    "lmtp_quit_timeout" ? long
    "lmtp_quote_rfc821_envelope" ? boolean
    "lmtp_randomize_addresses" ? boolean
    "lmtp_rcpt_timeout" ? long
    "lmtp_rset_timeout" ? long
    "lmtp_sasl_auth_enable" ? boolean
    "lmtp_sasl_mechanism_filter" ? string
    "lmtp_sasl_password_maps" ? string
    "lmtp_sasl_path" ? string
    "lmtp_sasl_security_options" ? string[]
    "lmtp_sasl_tls_security_options" ? string
    "lmtp_sasl_tls_verified_security_options" ? string
    "lmtp_sasl_type" ? string
    "lmtp_send_xforward_command" ? boolean
    "lmtp_sender_dependent_authentication" ? boolean
    "lmtp_skip_5xx_greeting" ? boolean
    "lmtp_starttls_timeout" ? long
    "lmtp_tcp_port" ? long
    "lmtp_tls_CAfile" ? string
    "lmtp_tls_CApath" ? string
    "lmtp_tls_cert_file" ? string
    "lmtp_tls_dcert_file" ? string
    "lmtp_tls_dkey_file" ? string
    "lmtp_tls_enforce_peername" ? boolean
    "lmtp_tls_exclude_ciphers" ? string
    "lmtp_tls_key_file" ? string
    "lmtp_tls_loglevel" ? long
    "lmtp_tls_mandatory_ciphers" ? string
    "lmtp_tls_mandatory_exclude_ciphers" ? string
    "lmtp_tls_mandatory_protocols" ? string
    "lmtp_tls_note_starttls_offer" ? boolean
    "lmtp_tls_per_site" ? string
    "lmtp_tls_policy_maps" ? string
    "lmtp_tls_scert_verifydepth" ? long
    "lmtp_tls_secure_cert_match" ? string
    "lmtp_tls_security_level" ? string
    "lmtp_tls_session_cache_database" ? string
    "lmtp_tls_session_cache_timeout" ? long
    "lmtp_tls_verify_cert_match" ? string
    "lmtp_use_tls" ? boolean
    "lmtp_xforward_timeout" ? long
    "local_command_shell" ? string
    "local_destination_concurrency_limit" ? long
    "local_destination_recipient_limit" ? long
    "local_header_rewrite_clients" ? string
    "local_recipient_maps" ? string
    "local_transport" ? postfix_lookup
    "luser_relay" ? string
    "mail_name" ? string
    "mail_owner" ? string
    "mail_release_date" ? long
    "mail_spool_directory" ? string
    "mail_version" ? string
    "mailbox_command" ? string
    "mailbox_command_maps" ? string
    "mailbox_delivery_lock" ? string
    "mailbox_size_limit" ? long
    "mailbox_transport" ? string
    "mailbox_transport_maps" ? string
    "mailq_path" ? string
    "manpage_directory" ? string
    "maps_rbl_domains" ? string
    "maps_rbl_reject_code" ? long
    "masquerade_classes" ? string[]
    "masquerade_domains" ? string[]
    "masquerade_exceptions" ? string[]
    "max_idle" ? long
    "max_use" ? long
    "maximal_backoff_time" ? long
    "maximal_queue_lifetime" ? long
    "message_reject_characters" ? string
    "message_size_limit" ? long
    "message_strip_characters" ? string
    "milter_command_timeout" ? long
    "milter_connect_macros" ? string
    "milter_connect_timeout" ? long
    "milter_content_timeout" ? long
    "milter_data_macros" ? string
    "milter_default_action" ? string
    "milter_end_of_data_macros" ? string
    "milter_helo_macros" ? string
    "milter_macro_daemon_name" ? string
    "milter_macro_v" ? string
    "milter_mail_macros" ? string
    "milter_protocol" ? long
    "milter_rcpt_macros" ? string
    "milter_unknown_command_macros" ? string
    "mime_boundary_length_limit" ? long
    "mime_header_checks" ? string
    "mime_nesting_limit" ? long
    "minimal_backoff_time" ? long
    "multi_recipient_bounce_reject_code" ? long
    "mydestination" ? string[]
    "mydomain" ? string
    "myhostname" ? string
    "mynetworks" ? string
    "mynetworks_style" ? string
    "myorigin" ? string
    "nested_header_checks" ? string
    "newaliases_path" ? string
    "non_fqdn_reject_code" ? long
    "non_smtpd_milters" ? string
    "notify_classes" ? string[]
    "owner_request_special" ? boolean
    "parent_domain_matches_subdomains" ? string[]
    "permit_mx_backup_networks" ? string
    "pickup_service_name" ? string
    "plaintext_reject_code" ? long
    "prepend_delivered_header" ? string[]
    "process_id_directory" ? string
    "propagate_unmatched_extensions" ? string[]
    "proxy_interfaces" ? string
    "proxy_read_maps" ? string[]
    "qmgr_clog_warn_time" ? long
    "qmgr_fudge_factor" ? long
    "qmgr_message_active_limit" ? long
    "qmgr_message_recipient_limit" ? long
    "qmgr_message_recipient_minimum" ? long
    "qmqpd_authorized_clients" ? string
    "qmqpd_error_delay" ? long
    "qmqpd_timeout" ? long
    "queue_directory" ? string
    "queue_file_attribute_count_limit" ? long
    "queue_minfree" ? long
    "queue_run_delay" ? long
    "queue_service_name" ? string
    "rbl_reply_maps" ? string
    "readme_directory" ? boolean
    "receive_override_options" ? string
    "recipient_bcc_maps" ? string
    "recipient_canonical_classes" ? string[]
    "recipient_canonical_maps" ? string
    "recipient_delimiter" ? string
    "reject_code" ? long
    "relay_clientcerts" ? string
    "relay_destination_concurrency_limit" ? string
    "relay_destination_recipient_limit" ? string
    "relay_domains" ? string
    "relay_domains_reject_code" ? long
    "relay_recipient_maps" ? string
    "relay_transport" ? string
    "relayhost" ? string
    "relocated_maps" ? string
    "remote_header_rewrite_domain" ? string
    "require_home_directory" ? boolean
    "resolve_dequoted_address" ? boolean
    "resolve_null_domain" ? boolean
    "resolve_numeric_domain" ? boolean
    "rewrite_service_name" ? string
    "sample_directory" ? string
    "sender_bcc_maps" ? string
    "sender_canonical_classes" ? string[]
    "sender_canonical_maps" ? string
    "sender_dependent_relayhost_maps" ? string
    "sendmail_path" ? string
    "service_throttle_time" ? long
    "setgid_group" ? string
    "show_user_unknown_table_name" ? boolean
    "showq_service_name" ? string
    "smtp_always_send_ehlo" ? boolean
    "smtp_bind_address" ? string
    "smtp_bind_address6" ? string
    "smtp_cname_overrides_servername" ? boolean
    "smtp_connect_timeout" ? long
    "smtp_connection_cache_destinations" ? string
    "smtp_connection_cache_on_demand" ? boolean
    "smtp_connection_cache_time_limit" ? long
    "smtp_connection_reuse_time_limit" ? long
    "smtp_data_done_timeout" ? long
    "smtp_data_init_timeout" ? long
    "smtp_data_xfer_timeout" ? long
    "smtp_defer_if_no_mx_address_found" ? boolean
    "smtp_destination_concurrency_limit" ? string
    "smtp_destination_recipient_limit" ? string
    "smtp_discard_ehlo_keyword_address_maps" ? string
    "smtp_discard_ehlo_keywords" ? string
    "smtp_enforce_tls" ? boolean
    "smtp_fallback_relay" ? string
    "smtp_generic_maps" ? string
    "smtp_helo_name" ? string
    "smtp_helo_timeout" ? long
    "smtp_host_lookup" ? string
    "smtp_line_length_limit" ? long
    "smtp_mail_timeout" ? long
    "smtp_mx_address_limit" ? long
    "smtp_mx_session_limit" ? long
    "smtp_never_send_ehlo" ? boolean
    "smtp_pix_workaround_delay_time" ? long
    "smtp_pix_workaround_threshold_time" ? long
    "smtp_quit_timeout" ? long
    "smtp_quote_rfc821_envelope" ? boolean
    "smtp_randomize_addresses" ? boolean
    "smtp_rcpt_timeout" ? long
    "smtp_rset_timeout" ? long
    "smtp_sasl_auth_enable" ? boolean
    "smtp_sasl_mechanism_filter" ? string
    "smtp_sasl_password_maps" ? string
    "smtp_sasl_path" ? string
    "smtp_sasl_security_options" ? string[]
    "smtp_sasl_tls_security_options" ? string
    "smtp_sasl_tls_verified_security_options" ? string
    "smtp_sasl_type" ? string
    "smtp_send_xforward_command" ? boolean
    "smtp_sender_dependent_authentication" ? boolean
    "smtp_skip_5xx_greeting" ? boolean
    "smtp_skip_quit_response" ? boolean
    "smtp_starttls_timeout" ? long
    "smtp_tls_CAfile" ? string
    "smtp_tls_CApath" ? string
    "smtp_tls_cert_file" ? string
    "smtp_tls_dcert_file" ? string
    "smtp_tls_dkey_file" ? string
    "smtp_tls_enforce_peername" ? boolean
    "smtp_tls_exclude_ciphers" ? string
    "smtp_tls_key_file" ? string
    "smtp_tls_loglevel" ? long
    "smtp_tls_mandatory_ciphers" ? string
    "smtp_tls_mandatory_exclude_ciphers" ? string
    "smtp_tls_mandatory_protocols" ? string[]
    "smtp_tls_note_starttls_offer" ? boolean
    "smtp_tls_per_site" ? string
    "smtp_tls_policy_maps" ? string
    "smtp_tls_scert_verifydepth" ? long
    "smtp_tls_secure_cert_match" ? string[]
    "smtp_tls_security_level" ? string
    "smtp_tls_session_cache_database" ? string
    "smtp_tls_session_cache_timeout" ? long
    "smtp_tls_verify_cert_match" ? string
    "smtp_use_tls" ? boolean
    "smtp_xforward_timeout" ? long
    "smtpd_authorized_verp_clients" ? string
    "smtpd_authorized_xclient_hosts" ? string
    "smtpd_authorized_xforward_hosts" ? string
    "smtpd_banner" ? string
    "smtpd_client_connection_count_limit" ? long
    "smtpd_client_connection_rate_limit" ? long
    "smtpd_client_event_limit_exceptions" ? string
    "smtpd_client_message_rate_limit" ? long
    "smtpd_client_new_tls_session_rate_limit" ? long
    "smtpd_client_recipient_rate_limit" ? long
    "smtpd_client_restrictions" ? string
    "smtpd_data_restrictions" ? string
    "smtpd_delay_open_until_valid_rcpt" ? boolean
    "smtpd_delay_reject" ? boolean
    "smtpd_discard_ehlo_keyword_address_maps" ? string
    "smtpd_discard_ehlo_keywords" ? string
    "smtpd_end_of_data_restrictions" ? string
    "smtpd_enforce_tls" ? boolean
    "smtpd_error_sleep_time" ? long
    "smtpd_etrn_restrictions" ? string
    "smtpd_expansion_filter" ? string
    "smtpd_forbidden_commands" ? string
    "smtpd_hard_error_limit" ? long
    "smtpd_helo_required" ? boolean
    "smtpd_helo_restrictions" ? string
    "smtpd_history_flush_threshold" ? long
    "smtpd_junk_command_limit" ? long
    "smtpd_milters" ? string
    "smtpd_noop_commands" ? string
    "smtpd_null_access_lookup_key" ? string
    "smtpd_peername_lookup" ? boolean
    "smtpd_policy_service_max_idle" ? long
    "smtpd_policy_service_max_ttl" ? long
    "smtpd_policy_service_timeout" ? long
    "smtpd_proxy_ehlo" ? string
    "smtpd_proxy_filter" ? string
    "smtpd_proxy_timeout" ? long
    "smtpd_recipient_limit" ? long
    "smtpd_recipient_overshoot_limit" ? long
    "smtpd_recipient_restrictions" ? string[]
    "smtpd_reject_udicted_recipient" ? boolean
    "smtpd_reject_udicted_sender" ? boolean
    "smtpd_restriction_classes" ? string
    "smtpd_sasl_auth_enable" ? boolean
    "smtpd_sasl_authenticated_header" ? boolean
    "smtpd_sasl_exceptions_networks" ? string
    "smtpd_sasl_local_domain" ? string
    "smtpd_sasl_path" ? string
    "smtpd_sasl_security_options" ? string
    "smtpd_sasl_tls_security_options" ? string
    "smtpd_sasl_type" ? string
    "smtpd_sender_login_maps" ? string
    "smtpd_sender_restrictions" ? string
    "smtpd_soft_error_limit" ? long
    "smtpd_starttls_timeout" ? long
    "smtpd_timeout" ? long
    "smtpd_tls_CAfile" ? string
    "smtpd_tls_CApath" ? string
    "smtpd_tls_always_issue_session_ids" ? boolean
    "smtpd_tls_ask_ccert" ? boolean
    "smtpd_tls_auth_only" ? boolean
    "smtpd_tls_ccert_verifydepth" ? long
    "smtpd_tls_cert_file" ? string
    "smtpd_tls_dcert_file" ? string
    "smtpd_tls_dh1024_param_file" ? string
    "smtpd_tls_dh512_param_file" ? string
    "smtpd_tls_dkey_file" ? string
    "smtpd_tls_exclude_ciphers" ? string
    "smtpd_tls_key_file" ? string
    "smtpd_tls_loglevel" ? long
    "smtpd_tls_mandatory_ciphers" ? string
    "smtpd_tls_mandatory_exclude_ciphers" ? string
    "smtpd_tls_mandatory_protocols" ? string[]
    "smtpd_tls_received_header" ? boolean
    "smtpd_tls_req_ccert" ? boolean
    "smtpd_tls_security_level" ? string
    "smtpd_tls_session_cache_database" ? string
    "smtpd_tls_session_cache_timeout" ? long
    "smtpd_tls_wrappermode" ? boolean
    "smtpd_use_tls" ? boolean
    "soft_bounce" ? boolean
    "stale_lock_time" ? long
    "strict_7bit_headers" ? boolean
    "strict_8bitmime" ? boolean
    "strict_8bitmime_body" ? boolean
    "strict_mime_encoding_domain" ? boolean
    "strict_rfc821_envelopes" ? boolean
    "sun_mailtool_compatibility" ? boolean
    "swap_bangpath" ? boolean
    "syslog_facility" ? string
    "syslog_name" ? string
    "tls_daemon_random_bytes" ? long
    "tls_export_cipherlist" ? string
    "tls_high_cipherlist" ? string
    "tls_low_cipherlist" ? string
    "tls_medium_cipherlist" ? string
    "tls_null_cipherlist" ? string
    "tls_random_bytes" ? long
    "tls_random_exchange_name" ? string
    "tls_random_prng_update_period" ? long
    "tls_random_reseed_period" ? long
    "tls_random_source" ? postfix_lookup
    "trace_service_name" ? string
    "transport_maps" ? string
    "transport_retry_time" ? long
    "trigger_timeout" ? long
    "undisclosed_recipients_header" ? string
    "unknown_address_reject_code" ? long
    "unknown_client_reject_code" ? long
    "unknown_hostname_reject_code" ? long
    "unknown_local_recipient_reject_code" ? long
    "unknown_relay_recipient_reject_code" ? long
    "unknown_virtual_alias_reject_code" ? long
    "unknown_virtual_mailbox_reject_code" ? long
    "unverified_recipient_reject_code" ? long
    "unverified_sender_reject_code" ? long
    "verp_delimiter_filter" ? string
    "virtual_alias_domains" ? string
    "virtual_alias_expansion_limit" ? long
    "virtual_alias_maps" ? string
    "virtual_alias_recursion_limit" ? long
    "virtual_destination_concurrency_limit" ? string
    "virtual_destination_recipient_limit" ? string
    "virtual_gid_maps" ? string
    "virtual_mailbox_base" ? string
    "virtual_mailbox_domains" ? string
    "virtual_mailbox_limit" ? long
    "virtual_mailbox_lock" ? string
    "virtual_mailbox_maps" ? string
    "virtual_minimum_uid" ? long
    "virtual_transport" ? string
    "virtual_uid_maps" ? string
} = dict();

@{
    Define multiple Postfix databases
}
type postfix_databases = {
    @{ LDAP databases, indexed by file name (relative to /etc/postfix)}
    'ldap' ? postfix_ldap_database{}
};

@{
    Entries in the master.cf file. See the master man page for more
    details.
}
type postfix_master = {
    "type" : string
    "private" : boolean = true
    "unprivileged" : boolean = true
    "chroot" : boolean = true
    "wakeup" : long = 0
    "maxproc" : long = 100
    "command" : string
    "name" : string
};

type postfix_component = {
    include structure_component
    @{ Contents of the main.cf file }
    'main' : postfix_main
    @{ Contents of the master.cf file }
    'master' : postfix_master[]
    @{ Definition of Postfix databases }
    'databases' ? postfix_databases
};
