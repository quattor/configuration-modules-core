object template profile_with_ldap;

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

prefix "/software/components/postfix/databases/ldap/ldap-aliases.cf";

"result_format" = "%s";