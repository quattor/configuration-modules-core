unique template yumdnf_base;

variable SPMA_BACKEND = 'yumdnf';

include 'base_with_config';

prefix "/software/modules";
"mod1/stream" = 'abc';
"mod3/stream" = 'def';
"mod3/enable" = false;
