unique template base;

function pkg_repl = { null; };
include 'components/ccm/config';
"/software/components/ccm/dependencies/pre" = null;

prefix "/software/components/ccm";
"profile" = "https://my.server/myprofile";
"configFile" = "/etc/ccm.conf";
"ca_file" = "/etc/sindes/ca/ca.crt";
"version" = "1.2.3";
"trust" = list("user/component.something/other.else@MY.REALM", "user2@OTHER.REALM", "host/all.lower.domain@all.lower.realm");
"group_readable" = "theadmins";
"principal" = "user/component.something/other.else@MY.REALM";
"keytab" = "/some/path/to/key.tab";
