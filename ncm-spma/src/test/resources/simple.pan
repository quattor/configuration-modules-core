object template simple;

prefix "/system/network";
"hostname" = "qwgtest";
"domainname" = "hosts.quattor.org";

prefix "/software/packages";

"ConsoleKit/_2e4_2e1_2d3_2eel6/arch/x86_64" = "sl620_x86_64";

prefix "/software/repositories/0";

"name" = "sl620_x86_64";
"owner" = "me@here.com";
"protocols/0/name" = "http";
"protocols/0/url" = "http://www.here.com";

prefix "/software/components/spma";

"run" = "yes";
"active" = true;
"dispatch" = true;
"userpkgs" = "no";
