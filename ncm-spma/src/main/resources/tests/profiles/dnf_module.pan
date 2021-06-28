object template dnf_module;

variable SPMA_BACKEND = 'yumdnf';

include 'base';

prefix "/software/modules";
"mod-something/stream" = '1.2.3';
"magic/stream" = 'woohoo';
"magic/enable" = false;
