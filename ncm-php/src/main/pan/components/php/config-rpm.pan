# ${license-info}
# ${developer-info}
# ${author-info}



unique template components/php/config-rpm;

include components/php/schema;
 
   # Package to install
#   "/software/packages" = pkg_repl('<phpRPMname>', '<ver>', '<arch>');

   "/software/components/php/active" ?= false;
   "/software/components/php/dispatch" ?= false;

#   "/software/packages"=pkg_repl("ncm-php", '1.0.9-1', "noarch");


