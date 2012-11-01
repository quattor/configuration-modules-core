object template ssh_simple;

prefix "/software/components/ssh/daemon";

"AllowGroups" = "a b c";
"PidFile" = "/var/run";

"/software/components/ssh/client" = nlist();
