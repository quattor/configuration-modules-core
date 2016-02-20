unique template metaconfig/nrpe/config;

include 'metaconfig/nrpe/schema';

bind "/software/components/metaconfig/services/{/etc/nagios/nrpe.cfg}/contents" = nrpe_service;

prefix "/software/components/metaconfig/services/{/etc/nagios/nrpe.cfg}";
"module" = "nrpe/main";
"mode" = 0640;
"daemons/nrpe" = "restart";

# The only non-trivial part of old ncm-nrpe: file group and configoption nrpe_group must match
# Default here is same as schema default.
@{variable NRPE_GROUP can be used to set both nrpe_group and file group}
variable NRPE_GROUP ?= 'nagios';
"group" ?= NRPE_GROUP;
"contents/nrpe_group" = NRPE_GROUP;

bind "/software/components/metaconfig/services/{/etc/nagios/nrpe.cfg}/group" = string with SELF == value("/software/components/metaconfig/services/{/etc/nagios/nrpe.cfg}/contents/nrpe_group");
