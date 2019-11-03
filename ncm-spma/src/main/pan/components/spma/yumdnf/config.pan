# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/spma/yumdnf/config;

include 'components/spma/yum/config';

prefix '/software/components/${project.artifactId}';
'packager' = 'yumdnf';
