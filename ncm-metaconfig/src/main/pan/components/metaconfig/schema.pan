# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

type ${project.artifactId}_extension = extensible {};

type caf_service_action = string with match(SELF, '^(restart|reload|stop_sleep_start)$');

type ${project.artifactId}_config =  {
     'mode' : long = 0644
     'owner' : string = 'root'
     'group' : string = 'root'
     'daemon' ? string[] with { deprecated(0, "daemon property has been deprecated, daemons should be used instead"); true; }
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
