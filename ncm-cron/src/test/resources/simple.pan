object template simple;

prefix "/software/components/cron";

"allow" = list("root", "sys");
"deny" = list("daemon", "bin" );
"securitypath" = "/etc";

"entries" = list(
    nlist("name", "echotest",
          "user", "root",
          "frequency", "10 3 * * *",
          "command", "/usr/sbin/echo one",
    ),
);