object template autofs_conf;

prefix "/software/components/autofs/conf/autofs";
"timeout" = 300;
"browse_mode" = false;

prefix "/software/components/autofs/conf/amd";
"dismount_interval" = 600;
"autofs_use_lofs" = false;

prefix "/software/components/autofs/conf/mountpoints";
"{/some/mount1}/dismount_interval" = 1200;
"{/some/mount2}/autofs_use_lofs" = true;
