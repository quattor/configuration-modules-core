object template krb5_profiles;

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_profiles.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_profiles.conf}";
"module" = "httpd/2.4/generic_server";
"daemons/httpd" = "restart";

variable FULL_HOSTNAME = 'myhost.domain';
variable HOSTNAME = 'myhost';
variable DB_IP = dict(HOSTNAME, '1.2.3.4');

final variable QUATTOR_SERVER_PROFILE_PORT ?= 444;
variable KRB5_REALM ?= 'YOUR.REALM';
variable KRB5_QUATTOR_SERVICE ?= 'host';

prefix '/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_profiles.conf}';
'module' = "httpd/generic_server";
'daemons' = dict("httpd", "restart");

'contents/modules' = list();
'contents/encodings/0/mime' = 'x-gzip';
'contents/encodings/0/extensions' = list('.gz', '.tgz');
'contents/listen/0' = dict(
    'name', DB_IP[HOSTNAME],
    'port', QUATTOR_SERVER_PROFILE_PORT,
);

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_profiles.conf}/contents/vhosts/profiles";
'port' = QUATTOR_SERVER_PROFILE_PORT;
'documentroot' = "/var/www/https";
'servername' = format("%s:%d", FULL_HOSTNAME, QUATTOR_SERVER_PROFILE_PORT);
'rewrite/maps/0/name' = "ACLmap";
'rewrite/maps/0/type' = "txt";
'rewrite/maps/0/source' = "/var/www/acl/ACLmap.txt";
'hostnamelookups' = true;
'ip/0' = DB_IP[HOSTNAME];

'nss/engine' = true;
# SSL 3 ciphers minues rc4 and 3des. SSL 2 is disabled by default.
'nss/ciphersuite' = list('-rsa_rc4_128_md5', '-rsa_rc4_128_sha', '-rsa_3des_sha', '-rsa_des_sha', '-rsa_rc4_40_md5',
    '-rsa_rc2_40_md5', '-rsa_null_md5', '-rsa_null_sha', '-fips_3des_sha','-fips_des_sha', '-fortezza',
    '-fortezza_rc4_128_sha', '-fortezza_null', '-rsa_des_56_sha', '-rsa_rc4_56_sha', '+rsa_aes_128_sha',
    '+rsa_aes_256_sha');
'nss/protocol' = list('TLSv1.0', 'TLSv1.1', 'TLSv1.2');
'nss/nickname' = 'Server-Cert';
'nss/certificatedatabase' = '/etc/httpd/alias';

'log/level' = 'warn';
'log/error' = format('logs/%s_error_log', 'profiles');
'log/transfer' = format('logs/%s_access_log', 'profiles');
'log/custom' = append(dict(
    'location', format("logs/%s_request_log", 'profiles'),
    'name', "ssl_combined",
));

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_profiles.conf}/contents/vhosts/profiles/directories/0";
"name" = "/var/www/https/profiles";
"rewrite/rules/0/conditions/0" = dict(
    "test", "${ACLmap:%{REMOTE_HOST}|NO}",
    "pattern", "NO",
);
"rewrite/rules/0/conditions/1" = dict(
    "test", "%{REMOTE_USER}",
    "pattern", format("^%s/(.+)@%s$", KRB5_QUATTOR_SERVICE, KRB5_REALM),
);
'rewrite/rules/0/regexp' = '^(.*/)?.*\.(xml|json)(\.gz)?$';
'rewrite/rules/0/destination' = '$1%1.$2$3';
'rewrite/rules/0/flags/0' = "L";
'auth/require' = dict("type", "valid-user");
'auth/name' = "Quattor Kerberos Login";
'auth/type' = "GSSAPI";
'gssapi/sslonly' = true;
'gssapi/credstore' = list('keytab:/etc/httpd/conf/ipa.keytab');
