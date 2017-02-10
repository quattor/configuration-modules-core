object template simpleaccounts;

function pkg_repl = { null; };
include 'components/accounts/config';
'/software/components/accounts/dependencies' = null;

prefix "/software/components/accounts/users/test";

"uid" = 1;
"groups" = list("foo", "bar", "baz");
"comment" = "A test account";
"homeDir" = "/home/test";
