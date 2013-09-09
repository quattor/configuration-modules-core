object template openldap;

prefix "/software/components/openldap";
"conf_file" = "/etc/openldap/slapd.conf";
"database"= ""; # force new style

"global/include_schema/0" = "/etc/openldap/schema/core.schema";

"databases/0/class" = "bdb";


"global/monitoring" = true;

