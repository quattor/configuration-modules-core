object template trivial_profile;

function pkg_repl = { null; };
include 'components/useraccess/config';
'/software/components/useraccess/dependencies' = null;

prefix "/software/components/useraccess";

"roles/root/ssh_keys_urls/0" = "file://foo/bar";
"users/root/roles/0" = "root";
"users/root/ssh_keys/0" = "apublickey";
