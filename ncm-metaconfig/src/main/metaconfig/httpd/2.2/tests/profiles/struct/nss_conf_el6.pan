structure template struct/nss_conf_el6;

"modules" = append(dict(
    "name", "nss_module",
    "path", "modules/libmodnss.so"));

"listen" = append(dict(
    "port", 8443));

"type/add" = list(
    dict(
        "name", "application/x-x509-ca-cert",
        "target", list(".crt"),
        ),
    dict(
        "name", "application/x-pkcs7-crl",
        "target", list(".crl"),
        ),
);

"nss" = dict(
    "passphrasedialog", "builtin",
    "passphrasehelper", "/usr/sbin/nss_pcache",

    "sessioncachesize", 10000,
    "sessioncachetimeout", 100,
    "session3cachetimeout", 86400,

    "renegotiation", false,
    "requiresafenegotiation", false,

);

"vhosts/base" = create("struct/default_vhost",
    "documentroot", "/var/www/cgi-bin",
    "port", 8443);


"vhosts/base/log/error" = "logs/nss_error_log";
"vhosts/base/log/transfer" = "logs/nss_access_log";
"vhosts/base/log/level" = "warn";

"vhosts/base/nss/nickname" ?= "server-cert";
"vhosts/base/nss/engine" = true;
# SSLv3,TLSv1.0,TLSv1.1
"vhosts/base/nss/protocol" =  list("TLSv1.0");
"vhosts/base/nss/ciphersuite" = list('+rsa_3des_sha', '-rsa_des_56_sha', '+rsa_des_sha', '-rsa_null_md5', '-rsa_null_sha', '-rsa_rc2_40_md5', '+rsa_rc4_128_md5', '-rsa_rc4_128_sha', '-rsa_rc4_40_md5', '-rsa_rc4_56_sha', '-fortezza', '-fortezza_rc4_128_sha', '-fortezza_null', '-fips_des_sha', '+fips_3des_sha', '-rsa_aes_128_sha', '-rsa_aes_256_sha');
"vhosts/base/nss/certificatedatabase" = "/etc/httpd/alias";


"vhosts/base/files" = list(dict(
    "regex", true,
    "name", '\.(cgi|shtml|phtml|php3?)$',
    "nss", dict(
        "options", list("+StdEnvVars"),
    ),
));
"vhosts/base/directories" = list(dict(
    "name", "/var/www/cgi-bin",
    "nss", dict(
        "options", list("+StdEnvVars"),
    ),
));

