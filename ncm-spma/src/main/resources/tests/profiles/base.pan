unique template base;

include "components/spma/schema";

'/software/components/spma' = dict();
'/software/packages' = dict();
'/software/groups' = dict();

prefix "/software/repositories/0";
"enabled" = true;
"excludepkgs/0" = "pkg1";
"excludepkgs/1" = "*pkg2*";
"gpgcheck" = false;
"name" = "zero";
"owner" = "me@here.come";
"protocols/0/name" = "http";
"protocols/0/url" = "http://some.where/repoone";
"skip_if_unavailable" = false;

prefix "/software/repositories/1";
"enabled" = false;
"excludepkgs/0" = "dont";
"excludepkgs/1" = "want";
"gpgcheck" = true;
"name" = "one";
"owner" = "everyone@everywhere.com";
"protocols/0/name" = "http";
"protocols/0/url" = "http://not.here/woohoo";
"protocols/1/name" = "http";
"protocols/1/url" = "http://not.here/either";
"skip_if_unavailable" = true;

prefix "/software/repositories/2";
"enabled" = false;
"includepkgs/0" = "alot";
"includepkgs/1" = "*more*";
"name" = "two";
"owner" = "me@my.com";
"protocols/0/cacert" = "/etc/pki/CA/cert.pem";
"protocols/0/clientcert" = "/etc/pki/cert/pem";
"protocols/0/clientkey" = "/etc/pki/key.pem";
"protocols/0/name" = "http";
"protocols/0/url" = "https://super.secret/repo";
"proxy" = "";
"skip_if_unavailable" = false;
