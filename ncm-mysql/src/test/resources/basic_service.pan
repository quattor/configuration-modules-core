object template basic_service;

prefix "/software/components/mysql";
"serviceName" = "mariadb";
prefix "/software/components/mysql/servers/one";
"host" = 'localhost';
"adminpwd" = 'r00t';
"adminuser" = "root";

prefix "/software/components/mysql/databases/opennebula";
"server" = "one";
"users/oneadmin/password" = 'p4ss';
"users/oneadmin/rights" = list("ALL PRIVILEGES");
"createDb" = false;
"initScript/file" = "/dev/null";

