object template users/consistent;

prefix "/software/components/accounts";

"preserved_accounts" = "none";

prefix "/software/components/accounts/groups";

"foo/gid" = 0;

prefix "/software/components/accounts/users";

"foo/uid" = 0;
"foo/groups/0" = 0;
"bar/uid" = 1;
"bar/groups/0" = "foo";
