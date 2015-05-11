object template ldap;

# custom template to test partial ldap.tt

prefix "/desc";
"autofs/map_name" = "am";
"default/bind_dn" = "db";
"group/name" = 'gn';
"krb5/keytab" = 'kt';
"netgroup/member" = 'nm';
"sasl/mech" = 'sam';
"sudo/hostnames" = 'sh';
"sudorule/hostnames" = 'sh';
"tls/key" = 'tk';
"tls/cacert" = 'ca';
"tls/cipher_suite" = list("c1", "c2");
"user/shell" = "us";
"uri" = list("u1","u2");

