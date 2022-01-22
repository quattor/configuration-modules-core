object template ipa;

# custom template to test partial ipa.tt

prefix "/desc";
'krb5/validate' = true;
'krb5/realm' = 'MY.REALM';
'krb5/canonicalize'  = false;
'krb5/server'  = list('k1', 'k2');
'krb5/backup_server'  = list('k3', 'k4');

'ldap/deref_threshold' = 5;

'dyndns/update' = false;
'dyndns/ttl' = 123;
'dyndns/iface' = list('em1', 'em2');

'search_base/hbac' = 'abc';
'search_base/host' = 'def';

'domain' = 'MY.DOMAIN';
'server' = list('h1', 'h2');
'backup_server'  = list('h3', 'h4');
'enable_dns_sites' = true;
