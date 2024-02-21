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
"users/oneuser/password" = '*2F01F3D078AE27EB3017F8F53DF9C31AEA6D90C5'; # clear password : plop
"users/oneuser/encrypted_adminpwd" = true;
"users/oneuser/rights" = list("ALL PRIVILEGES");
"createDb" = false;
"initScript/file" = "/dev/null";

