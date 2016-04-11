unique template base;

function pkg_repl = { null; };
include 'components/freeipa/config';
"/software/components/freeipa/dependencies/pre" = null;

prefix "/software/components/freeipa";
"primary" = "myhost.example.com";

prefix "/system/network";
"hostname" = "myhost";
"domainname" = "example.com";
