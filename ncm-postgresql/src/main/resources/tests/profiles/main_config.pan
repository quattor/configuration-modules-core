object template main_config;

include 'components/postgresql/schema';

bind "/config" = postgresql_mainconfig;

prefix "/config";
"archive_command" = "my archive command";
"archive_mode" = true;
"archive_timeout" = 10;
"listen_addresses" = list('a', 'b', 'c');
