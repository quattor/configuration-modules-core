object template krb5_sunstone;

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_sunstone.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_sunstone.conf}";
"module" = "httpd/2.4/generic_server";
"daemons/httpd" = "restart";

variable FULL_HOSTNAME = 'myhost.domain';
variable HOSTNAME = 'myhost';
variable DB_IP = dict(HOSTNAME, '1.2.3.4');

variable KRB5_REALM ?= 'YOUR.REALM';
variable KRB5_QUATTOR_SERVICE ?= 'host';

variable SUNSTONE_PUBLIC_DIR = "/usr/lib/one/sunstone/public";

prefix '/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_sunstone.conf}';
'module' = "httpd/generic_server";
'daemons' = dict("httpd", "restart");

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_sunstone.conf}/contents/vhosts/sunstone";
'port' = 443;
'documentroot' = SUNSTONE_PUBLIC_DIR;
'servername' = format("%s:%d", FULL_HOSTNAME, 443);
'passenger/user' = 'oneadmin';

    'hostnamelookups' = true;
'ip/0' = DB_IP[HOSTNAME];

'nss/engine' = true;
# SSL 3 ciphers minus rc4 and 3des. SSL 2 is disabled by default.
'nss/ciphersuite' = list('-rsa_rc4_128_md5', '-rsa_rc4_128_sha', '-rsa_3des_sha', '-rsa_des_sha', '-rsa_rc4_40_md5', '-rsa_rc2_40_md5', '-rsa_null_md5', '-rsa_null_sha', '-fips_3des_sha','-fips_des_sha', '-fortezza', '-fortezza_rc4_128_sha', '-fortezza_null', '-rsa_des_56_sha', '-rsa_rc4_56_sha', '+rsa_aes_128_sha', '+rsa_aes_256_sha');
'nss/protocol' = list('TLSv1.0', 'TLSv1.1', 'TLSv1.2');
'nss/nickname' = 'Server-Cert';
'nss/certificatedatabase' = '/etc/httpd/alias';

'log/level' = 'warn';
'log/error' = format('logs/%s_error_log', 'sunstone');
'log/transfer' = format('logs/%s_access_log', 'sunstone');
'log/custom' = append(dict(
    'location', format("logs/%s_request_log", 'sunstone'),
    'name', "ssl_combined",
));

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/krb5_sunstone.conf}/contents/vhosts/sunstone/directories/0";
"name" = SUNSTONE_PUBLIC_DIR;
'auth/require' = dict("type", "valid-user");
'auth/name' = "Sunstone Kerberos Login";
'auth/type' = "GSSAPI";
'gssapi/sslonly' = true;
'gssapi/credstore' = list('keytab:/etc/http.keytab');
'access' = dict('allowoverride', list('None'));
'options' = list('-MultiViews');
