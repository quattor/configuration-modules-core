unique template base;

function pkg_repl = { null; };
include 'components/postfix/config';
# remove the dependencies
'/software/components/postfix/dependencies' = null;


prefix "/software/components/postfix/master/0";

"name" = "foo";
"type" = "hello";
"command" = "Hello, world";
"private" = true;
"unprivileged" = true;
"chroot" = true;
"wakeup" = 100;
"maxproc" = 20;

prefix "/software/components/postfix/master/1";

"name" = "bar";
"type" = "world";
"private" = false;
"unprivileged" = false;
"chroot" = false;
"wakeup" = 100;
"maxproc" = 20;
"command" = "World, hello";

prefix "/software/components/postfix/main";
"alias_maps/0/name" = "/etc/aliases";
"alias_maps/0/type" = "hash";
"alias_maps/1/name" = "/etc/postfix/ldap-aliases.cf";
"alias_maps/1/type" = "ldap";
"default_privs" = "nobody";
"inet_interfaces/0" = "127.0.0.1";
"inet_interfaces/1" = "hostname.example.com";
"masquerade_classes/0" = "envelope_sender";
"masquerade_classes/1" = "header_sender";
"masquerade_domains/0" = "example.com";
"masquerade_exceptions/0" = "root";
"mydestination/0" = "$myhostname";
"mydestination/1" = "localhost.$mydomain";
"mydomain" = "example.com";
"myhostname" = "hostname.example.com";
"myorigin" = "example.com";
"relayhost" = "smtp.relay.example.com";
"unknown_local_recipient_reject_code" = 450;


prefix "/software/components/postfix/databases/ldap/ldap-aliases.cf";
"result_format" = "%s";
"server_host/0" = "my.host.example.com";
"search_base" = 'base';
"query_filter" = 'filter';
"result_format" = 'format';
"bind" = false;
