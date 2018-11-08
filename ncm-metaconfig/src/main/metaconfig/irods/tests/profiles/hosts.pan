object template hosts;

include 'metaconfig/irods/hosts';

prefix "/software/components/metaconfig/services/{/etc/irods/hosts_config.json}/contents";

"host_entries/0/address_type" = "local";
"host_entries/0/addresses/0/address" = "10.141.11.1";
"host_entries/0/addresses/1/address" = "test.example.org";

"host_entries/1/address_type" = "remote";
"host_entries/1/addresses/0/address" = "10.141.6.1";
"host_entries/1/addresses/1/address" = "test2.example.org";
"host_entries/1/addresses/2/address" = "test.other.domain";

