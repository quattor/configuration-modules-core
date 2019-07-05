declaration template metaconfig/beats/schema;

# METACONFIG_BEATS_VERSION can be:
# - pre6.0 for versions of filebeat <6.0, i.e 1.3, 5.0 etc
# - 6.0 for versions of filebeat >=6.0 and <6.3
# - 6.3 for versions of filebeat >=6.3
# Default to 'pre6.0' for backwards compatibility.
variable METACONFIG_BEATS_VERSION ?= 'pre6.0';

include format('metaconfig/beats/schema_%s', METACONFIG_BEATS_VERSION);
