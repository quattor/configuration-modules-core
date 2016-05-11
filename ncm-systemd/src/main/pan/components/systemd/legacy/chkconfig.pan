# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/legacy/chkconfig;

include 'components/${project.artifactId}/config';
include 'components/chkconfig/config';

'/software/components/${project.artifactId}/skip/service' = true;
'/software/components/chkconfig/ncm-module' = 'Systemd::Service::Component::chkconfig';
