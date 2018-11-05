object template guests;

include 'metaconfig/libvirtd/guests';

prefix "/software/components/metaconfig/services/{/etc/sysconfig/libvirt-guests}/contents";
"uris" = list("default", "lxc:///");
"on_boot" = "ignore";
"start_delay" = 0;
"on_shutdown" = "shutdown";
"parallel_shutdown" = 2;
"shutdown_timeout" = 600;
"bypass_cache" = true;
"sync_time" = true;
