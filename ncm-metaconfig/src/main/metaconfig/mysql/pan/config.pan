unique template metaconfig/mysql/config;

include 'metaconfig/mysql/schema';

bind "/software/components/metaconfig/services/{/etc/my.cnf.d/quattor.cnf}/contents" = type_mysql_cnf;

prefix "/software/components/metaconfig/services/{/etc/my.cnf.d/quattor.cnf}";
"mode" = 0640;
"owner" = "root";
"group" = "mysql";
"module" = "tiny";
"daemons/mariadb" = "restart";
