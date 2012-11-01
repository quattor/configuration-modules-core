object template ssh_simple;

prefix "/software/components/ssh/daemon/options";

"AllowGroups" = "a b c";
"PidFile" = "/var/run";

prefix "/software/components/ssh/daemon/comment_options";

"Foobar" = 1;

"/software/components/ssh/client" = nlist();
