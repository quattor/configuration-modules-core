object template password;

include 'base';


prefix "/software/components/grub/password";
"enabled" = true;
"password" = "1234";
"option" = "encrypted";


# use defaults from code except speed
"/hardware/console/serial" = dict("speed", 5678);
