object template recovery_done;

include 'simple';

prefix "/software/components/postgresql";
"config/main/port" = 2345;

prefix "/software/components/postgresql/recovery";
"config/standby_mode" = true;
# done = true is default; with default suffix

