object template basic;

function pkg_repl = { null; };
include 'components/authconfig/config';
'/software/components/authconfig/dependencies' = null;

"/system/network/interfaces" = dict('em1', true, 'em2', true);

prefix "/software/components/authconfig";
# test case_sensitive
"enableforcelegacy" = false; # boolean
"passalgorithm" = "md5"; # string
"safemode" = false; # boolean
"usecache" = false; # boolean
"usemd5" = true; # boolean
"useshadow" = true; # boolean

prefix "/software/components/authconfig/method/sssd";
"enable" = true; # boolean
"global/config_file_version" = 2; # long
"global/debug_level" = 528; # long
"global/reconnection_retries" = 3; # long
"global/services/0" = "nss"; # string
"global/services/1" = "pam"; # string
"global/try_inotify" = true; # boolean
"nss/debug_level" = 528;
"nss/entry_negative_timeout" = 15;
"nss/enum_cache_timeout" = 120;
"nss/filter_groups" = "root";
"nss/filter_users" = "root";
"nss/filter_users_in_groups" = true;
"nss/memcache_timeout" = 300;
"nssonly" = false;
"pam/debug_level" = 528;
"pam/get_domains_timeout" = 60;
"pam/offline_credentials_expiration" = 0;
"pam/offline_failed_login_attempts" = 0;
"pam/offline_failed_login_delay" = 5;
"pam/pam_id_timeout" = 5;
"pam/pam_pwd_expiration_warning" = 0;
"pam/pam_verbosity" = 1;

prefix "/software/components/authconfig/method/sssd/domains";
"test1/account_cache_expiration" = 0;
"test1/auth_provider" = "ldap";
"test1/cache_credentials" = true;
"test1/case_sensitive" = true;
"test1/debug_level" = 528;
"test1/dns_resolver_timeout" = 5;
"test1/entry_cache_timeout" = 21600;
"test1/enumerate" = true;
"test1/force_timeout" = 60;
"test1/full_name_format" = "%1$s@%2$s";
"test1/id_provider" = "ldap";
"test1/ldap/access_order" = "filter";
"test1/ldap/backup_uri/0" = "ldaps://myserver.mydomain";
"test1/ldap/backup_uri/1" = "ldaps://myotherserver.mydomain";
"test1/ldap/connection_expire_timeout" = 900;
"test1/ldap/default/authtok" = "awesome";
"test1/ldap/default/authtok_type" = "password";
"test1/ldap/default/bind_dn" = "cn=user,dc=domain,dc=whatever";
"test1/ldap/deref" = "never";
"test1/ldap/disable_paging" = false;
"test1/ldap/enumeration_refresh_timeout" = 300;
"test1/ldap/enumeration_search_timeout" = 60;
"test1/ldap/force_upper_case_realm" = false;
"test1/ldap/group/gid_number" = "gidNumber";
"test1/ldap/group/member" = "memberuid";
"test1/ldap/group/modify_timestamp" = "modifyTimestamp";
"test1/ldap/group/name" = "cn";
"test1/ldap/group/nesting_level" = 2;
"test1/ldap/group/object_class" = "posixGroup";
"test1/ldap/group/uuid" = "nsUniqueId";
"test1/ldap/id_mapping" = false;
"test1/ldap/id_use_start_tls" = false;
"test1/ldap/network_timeout" = 6;
"test1/ldap/ns_account_lock" = "nsAccountLock";
"test1/ldap/opt_timeout" = 6;
"test1/ldap/page_size" = 1000;
"test1/ldap/purge_cache_timeout" = 10800;
"test1/ldap/pwd_policy" = "none";
"test1/ldap/referrals" = true;
"test1/ldap/schema" = "rfc2307";
"test1/ldap/search_base" = "dc=domain,dc=wahtever";
"test1/ldap/search_timeout" = 6;
"test1/ldap/tls/cacert" = "/etc/pki/ca.pem";
"test1/ldap/tls/cert" = "/etc/pki/client_cert.pem";
"test1/ldap/tls/cipher_suite/0" = "TLSv1";
"test1/ldap/tls/key" = "/etc/pki/client_key.pem";
"test1/ldap/tls/reqcert" = "hard";
"test1/ldap/uri/0" = "ldaps://mymainserver.mydomain";
"test1/ldap/uri/1" = "ldaps://myothermainserver.mydomain";
"test1/ldap/use_object_class" = "posixAccount";
"test1/ldap/user/ad_account_expires" = "accountExpires";
"test1/ldap/user/ad_user_account_control" = "userAccountControl";
"test1/ldap/user/authorized_host" = "host";
"test1/ldap/user/authorized_service" = "authorizedService";
"test1/ldap/user/fullname" = "cn";
"test1/ldap/user/gecos" = "gecos";
"test1/ldap/user/gid_number" = "gidNumber";
"test1/ldap/user/home_directory" = "homeDirectory";
"test1/ldap/user/krb_last_pwd_change" = "krbLastPwdChange";
"test1/ldap/user/krb_password_expiration" = "krbPasswordExpiration";
"test1/ldap/user/member_of" = "memberOf";
"test1/ldap/user/modify_timestamp" = "modifyTimestamp";
"test1/ldap/user/nds_login_allowed_time_map" = "loginAllowedTimeMap";
"test1/ldap/user/nds_login_disabled" = "loginDisabled";
"test1/ldap/user/nds_login_expiration_time" = "loginDisabled";
"test1/ldap/user/principal" = "krbPrincipalName";
"test1/ldap/user/shadow_expire" = "shadowExpire";
"test1/ldap/user/shadow_inactive" = "shadowInactive";
"test1/ldap/user/shadow_last_change" = "shadowLastChange";
"test1/ldap/user/shadow_max" = "shadowMax";
"test1/ldap/user/shadow_min" = "shadowMin";
"test1/ldap/user/shadow_warning" = "shadowWarning";
"test1/ldap/user/shell" = "loginShell";
"test1/ldap/user/uid_number" = "uidNumber";
"test1/ldap/user/uuid" = "nsUniqueId";
"test1/lookup_family_order" = "ipv4_first";
"test1/max_id" = 123456;
"test1/min_id" = 234567;
"test1/proxy_fast_alias" = false;
"test1/re_expression" = "(?P<name>[^@]+)@?(?P<domain>[^@]*$)";
"test1/subdomain_homedir" = "/home/%d/%u";
"test1/access_provider" = "simple";
"test1/simple/allow_groups" = list("group1","group2");

# IPA
"test2/auth_provider" = "ipa";
"test2/ipa/krb5/validate" = true;
"test2/ipa/krb5/realm" = "MY.REALM";
"test2/ipa/krb5/canonicalize"  = false;

"test2/ipa/dyndns/update" = false;
"test2/ipa/dyndns/ttl" = 123;
"test2/ipa/dyndns/iface" = list("em1", "em2");

"test2/ipa/search_base/hbac" = "abc";
"test2/ipa/search_base/host" = "def";

"test2/ipa/domain" = "MY.DOMAIN";
"test2/ipa/server" = list("h1.mydomain.org", "h2.mydomain.org");
"test2/ipa/backup_server"  = list("h3.mydomain.org", "h4.mydomain.org");
"test2/ipa/enable_dns_sites" = true;
