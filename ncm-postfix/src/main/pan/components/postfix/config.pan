# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/postfix/config;

include { 'components/${project.artifactId}/config-common' };
include { 'components/postfix/config-rpm' };
