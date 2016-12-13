@maintainer{
    name = Luis Fernando Muñoz Mejías
    email = Luis.Munoz@UGent.be
}

@{
   Template describing a basic HTTPS virtual host.
}

structure template struct/default_vhost;

"servername" = FULL_HOSTNAME;
"port" = 443;
"documentroot" = "/var/www/https";
"ip/0" = DB_IP[HOSTNAME];
"ssl" = create("struct/basic_ssl");

"log/level" = "warn";
"log/error" = format("logs/%s_%s_error_log", value("servername"), value("port"));
"log/transfer" = format("logs/%s_%s_access_log", value("servername"), value("port"));
"log/custom"=append(dict(
    "location", format("logs/%s_%s_request_log", value("servername"), value("port")),
    "name", "ssl_combined"));
