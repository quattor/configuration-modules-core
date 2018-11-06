object template config;

include 'metaconfig/mysql/config';

prefix "/software/components/metaconfig/services/{/etc/my.cnf.d/quattor.cnf}/contents";
"mysqldump/user" = "root";
"mysqldump/password" = "my_database_password";
"mysqld/max_connections" = 2000;
