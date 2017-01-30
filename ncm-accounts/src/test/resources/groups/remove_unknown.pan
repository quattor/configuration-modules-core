object template groups/remove_unknown;

prefix "/software/components/accounts";

"groups/root/gid" = 0;
"groups/bin/gid" = 1;
"groups/daemon/gid" = 2;

"remove_unknown" = true;

"kept_groups" = dict("g1", "");