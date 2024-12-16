object template server_config;

# add this to test the actions/commands to trigger the main metaconfig bind
function pkg_repl = { null; };
include 'components/metaconfig/config';
# remove the dependencies
'/software/components/metaconfig/dependencies' = null;

include 'metaconfig/ssh/server_config';

prefix "/software/components/metaconfig/services/{/etc/ssh/sshd_config}/contents";

"main/AddressFamily" = "any";
"main/Ciphers" = list("aes128-ctr", "aes192-ctr", "aes256-ctr");
"main/PasswordAuthentication" = false;
"main/Subsystem" = dict("sftp", "internal-sftp");

"Match/0/criteria" = dict(
    "User", list("testuser2"),
    "Address", list("192.168.0.0/16", "!192.168.10.0/24"),
);
"Match/0/PasswordAuthentication" = true;

"Match/1/criteria" = dict(
    "All", true,
);
"Match/1/PasswordAuthentication" = false;
