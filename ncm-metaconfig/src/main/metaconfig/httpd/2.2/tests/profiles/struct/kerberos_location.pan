structure template struct/kerberos_location;

"kerberos/methodnegotiate" = true;
"kerberos/methodk5passwd" = false;
"kerberos/keytab" ?= "/etc/httpd/conf/kerberos.keytab";

"auth/name" = "Kerberos Login";
"auth/type" = "Kerberos";
"auth/require" = dict("type", "valid-user");

"ssl/requiressl" = true;
