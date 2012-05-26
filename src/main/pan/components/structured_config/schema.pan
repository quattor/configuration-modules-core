# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

type ${project.artifact_id}_extension = extensible {};

type ${project.artifactId}_config =  {
     'mode' : long = 0644
     'owner' : string = 'root'
     'group' : string = 'root'
     'daemon' ? string
     'module' : string
     'contents' : ${project.artifactId}_extension
} = nlist();

type ${project.artifactId}_component = {
    include structure_component
    'services' : ${project.artifactId}_config{}
};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
