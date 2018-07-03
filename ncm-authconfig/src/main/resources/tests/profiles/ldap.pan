object template ldap;

# custom template to test partial ldap.tt

include 'components/authconfig/schema';

prefix "/desc";
"autofs/map_name" = "am";
"default/bind_dn" = "db";
"group/name" = 'gn';
"krb5/keytab" = 'kt';
"netgroup/member" = 'nm';
"sasl/mech" = 'sam';
"sudo/hostnames" = 'sh';
"sudorule/host" = 'sh';
"tls/key" = 'tk';
"tls/cacert" = 'ca';
"tls/cipher_suite" = list("c1", "c2");
"user/shell" = "us";
"uri" = list("u1", "u2");
"user/object_class" = "user";
"krb5_canonicalize" = "true";
"krb5_realm" = "realm";

bind '/desc/' = authconfig_sssd_ldap;
