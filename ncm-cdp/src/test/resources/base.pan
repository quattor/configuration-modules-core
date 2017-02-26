object template base;

function pkg_repl = { null; };
include 'components/cdp/config';
'/software/components/cdp/dependencies' = null;

prefix "/software/components/cdp";

"configFile" = "/etc/cdp-listend.conf";
"version" = "1.2.3";
"fetch_offset" = 5;
"fetch_smear" = 8;
"nch_smear" = 10;
"port" = 7777;
