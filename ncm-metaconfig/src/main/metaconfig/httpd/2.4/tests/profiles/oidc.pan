object template oidc;

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/ssl.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/ssl.conf}";
"module" = "httpd/2.4/generic_server";
"daemons/httpd" = "restart";

variable FULL_HOSTNAME = 'myhost.domain';
variable HOSTNAME = 'myhost';
variable DB_IP = dict(HOSTNAME, '1.2.3.77');
"/software/components/metaconfig/services/{/etc/httpd/conf.d/ssl.conf}/contents" = create("struct/ssl_conf_el7");

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/ssl.conf}/contents/vhosts/base/oidc";
"responsetype" = list("id_token token2");
"scope" = list("openid email profile");
"clientid" = "abc123";
"clientsecret" = "supersecret";
"cryptopassphrase" = "evenmoresupersecret";
"redirecturi" = "https://my.org/service";

"providermetadataurl" = "https://accounts.google.com/.well-known/openid-configuration";

"statemaxnumberofcookies/number" = 10;
"statemaxnumberofcookies/delete" = true;
