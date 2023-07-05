object template ipmi;

include 'components/ipmi/schema';

prefix "/software/components/ipmi";

"channel" = 1;

"users/0/userid" = 1;
"users/0/login" = "login";
"users/0/password" = "password";
"users/0/priv" = 2;
