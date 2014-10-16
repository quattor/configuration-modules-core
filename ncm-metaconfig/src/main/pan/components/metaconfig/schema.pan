# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

type ${project.artifactId}_extension = extensible {};

# TODO add start/stop?
# TODO already add stop_sleep_start (with some fixed delay)?
# TODO support options like synchronous, delay,... ?
type caf_service_action = string with match(SELF, '^(restart|reload)$');

type ${project.artifactId}_config =  {
     'mode' : long = 0644
     'owner' : string = 'root'
     'group' : string = 'root'
     'daemon' ? string[]
     'daemons' ? caf_service_action{}
     'module' : string
     'backup' ? string
     'preamble' ? string
     'contents' : ${project.artifactId}_extension
} = nlist();

type ${project.artifactId}_component = {
    include structure_component
    'services' : ${project.artifactId}_config{}
};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
