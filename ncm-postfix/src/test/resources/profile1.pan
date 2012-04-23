object template profile1;

prefix "/software/components/postfix/master/foo";

"type" = "hello";
"command" = "Hello, world";
"private" = true;
"unprivileged" = true;
"chroot" = true;
"wakeup" = 100;
"maxproc" = 20;


prefix "/software/components/postfix/master/bar";

"type" = "world";
"private" = false;
"unprivileged" = false;
"chroot" = false;
"wakeup" = 100;
"maxproc" = 20;
"command" = "World, hello";
