object template md5password;

include 'base';
include "components/grub/config";

prefix "/software/components/grub/password";
"enabled" = true;
# this is technically an incorrect salt due to +, but it's
# the easiest way to make the regex issue visible
"password" = "$1$+DS97x/$z0phaR1SK9x7NDzLfGx7S/";
"option" = "md5";


# use defaults from code except speed
"/hardware/console/serial" = dict("speed", 5678);
