unique template metaconfig/graphite/config;

include 'metaconfig/graphite/schema';
bind "/software/components/metaconfig/services/{/etc/carbon/carbon.conf}/contents" = carbon_config;

prefix "/software/components/metaconfig/services/{/etc/carbon/carbon.conf}";
"module" = "graphite/carbon";
"mode" = 0644;

# basedir for storage etc etc
variable CARBON_BASEDIR ?= "/var/lib/carbon";

prefix "/software/components/metaconfig/services/{/etc/carbon/carbon.conf}/contents";
"cache/storage_dir" = CARBON_BASEDIR;
"cache/local_data_dir" = format("%s/whisper/", CARBON_BASEDIR);
"cache/whitelists_dir" = format("%s/lists/", CARBON_BASEDIR);

