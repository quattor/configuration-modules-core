object template requiredgroupmembers;

include 'components/accounts/schema';
include 'components/accounts/sysgroups';
include 'components/accounts/sysusers';

prefix "/software/components/accounts";
"remove_unknown" = true;
"preserved_accounts" = "dyn_user_group";

prefix "/software/components/accounts/users/test";

"uid" = 1;
"groups" = list("foo", "bar", "baz");
"comment" = "A test account";
"homeDir" = "/home/test";

# Group foo: one required member different from test
prefix "/software/components/accounts/groups/foo";
"gid" = 100;
"comment" = "group foo with required user bar";
"requiredMembers" = list("bar");

# Group bar: test also listed as a required member to
# check absence of duplicates, group member replaced.
# One required member not defined in the configuration.
prefix "/software/components/accounts/groups/bar";
"gid" = 101;
"comment" = "group bar with required users foo and test";
"requiredMembers" = list("foo2", "test");
"replaceMembers" = true;

# Group bar: test also listed as a required member to
# check absence of duplicates (as bar is also one of the group defined
# in user test), group members not replaced.
prefix "/software/components/accounts/groups/bar2";
"gid" = 102;
"comment" = "group bar with required users foo and test, (required members merged)";
"requiredMembers" = list("foo", "test");
"replaceMembers" = false;

# Group test: no explicit members, changed id compared
# to original one.
prefix "/software/components/accounts/groups/test";
"gid" = 50;
"comment" = "group test with no explicit member (changed id)";

# Group test2: no explicit members, changed id compared
# to original one.
prefix "/software/components/accounts/groups/test2";
"gid" = 51;
"comment" = "group test2 with a changed id and explicit members";
"requiredMembers" = list("foo");
