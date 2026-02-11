object template dnf_modules;

include 'base_with_config';

prefix "/software/modules";
"wanted_mod/stream" = 'default';
"postgresql/stream" = '13';
"nodejs/stream" = '16';
