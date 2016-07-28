object template profile1;

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
