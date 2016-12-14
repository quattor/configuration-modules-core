unique template metaconfig/ganesha/config;

variable METACONFIG_GANESHA_VERSION ?= 'v1';

include format("metaconfig/ganesha/config_%s" , METACONFIG_GANESHA_VERSION);

