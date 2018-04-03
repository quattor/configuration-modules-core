object template recovery_suff;

include 'simple';

prefix "/software/components/postgresql";
"config/main/port" = 2345;

prefix "/software/components/postgresql/recovery";
"config/standby_mode" = true;
"suffix" = ".conf.pcmk"; # done = true is default
