object template rollback;

function pkg_repl = { null; };
include 'components/shorewall/config';
# remove the dependencies
'/software/components/shorewall/dependencies' = null;

prefix "/software/components/shorewall";

"interfaces/0/zone" = "z1";
"interfaces/0/interface" = "eth0";
"policy/0/src" = "z1";
"policy/0/dst" = "all";
"policy/0/policy" = "accept";
