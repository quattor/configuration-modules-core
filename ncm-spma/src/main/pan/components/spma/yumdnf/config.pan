# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/spma/yumdnf/config;

include 'components/spma/config-common-yum';

prefix '/software/components/${project.artifactId}';
'packager' = 'yumdnf';
'register_change' = append("/software/modules");

'/software/modules' ?= dict();

bind "/software/components/spma" = component_spma_yumdnf;
bind "/software/groups" = dict with length(SELF) == 0;
bind '/software/modules' = component_spma_dnf_module_simple{};
