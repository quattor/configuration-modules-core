object template config;

include 'metaconfig/ssh_config/config';

prefix "/software/components/metaconfig/services/{/etc/ssh/ssh_config}/contents";


"Host/hostname.example.com/ProxyCommand" = "testcommand";
"Host/hostname.example.com/User" = "testuser";
"Host/hostname2.example.com/ProxyCommand" = "testcommand2";
"Host/hostname2.example.com/User" = "testuser2";
