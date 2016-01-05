object template requiredgroupmembers;

include 'components/accounts/schema';
include 'components/accounts/sysgroups';
include 'components/accounts/sysusers';

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
# check absence of duplicates
prefix "/software/components/accounts/groups/bar";
"gid" = 101;
"comment" = "group bar with required users foo and test";
"requiredMembers" = list("foo","test"); 
