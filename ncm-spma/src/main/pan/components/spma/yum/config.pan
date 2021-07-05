# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/spma/yum/config;

include 'components/spma/config-common-yum';

prefix '/software/components/${project.artifactId}';
'packager' = 'yum';


bind "/software/components/spma" = component_spma_yum;
bind "/software/groups" = SOFTWARE_GROUP{} with {
    if (length(SELF) > 0) deprecated(0, 'Support for YUM groups will be removed in a future release.');
    true;
};
