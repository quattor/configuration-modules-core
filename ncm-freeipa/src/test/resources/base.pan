unique template base;

function pkg_repl = { null; };
include 'components/freeipa/config';
"/software/components/freeipa/dependencies/pre" = null;

prefix "/software/components/freeipa";
"realm" = "MY.REALM";
"primary" = "myhost.example.com";
"domain" = 'com';
"hostcert" = true;
"host/ip_address" = "1.2.3.4";
"host/macaddress" = list("aa:bb:cc:dd:ee:ff");
"principals/aii/principal" = "quattor-aii";
"principals/aii/keytab" = "/etc/quattor-aii.keytab";


prefix "/system/network";
"hostname" = "myhost";
"domainname" = "example.com";
