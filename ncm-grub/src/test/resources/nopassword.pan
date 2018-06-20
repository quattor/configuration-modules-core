object template nopassword;

include 'base';


prefix "/software/components/grub/password";
"enabled" = false;
"option" = "encrypted";

# use defaults from code except speed
"/hardware/console/serial" = dict("speed", 5678);
