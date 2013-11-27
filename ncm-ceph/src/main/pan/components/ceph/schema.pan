# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

type ${project.artifactId}_config = {

} = nlist();

type ${project.artifactId}_component = {
    include structure_component
    'config' : ${project.artifactId}_config
};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
