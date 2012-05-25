object template users/allbroken;

prefix "/software/components/accounts/groups";

"foo/gid" = 0;
"bar/gid" = 0;

prefix "/software/components/accounts/users";

"foo/uid" = 0;
"foo/groups/0" = 0;
"bar/uid" = 0;
"bar/groups/0" = "foo";