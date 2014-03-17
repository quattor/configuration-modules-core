# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

#
# Check for conflicts between the filename and the service keys.
# Each written file should correspond with excatly one service.
#
function is_${project.artifactId}_services = {
    # /software/components/${project.artifactId}/services is passed as only argument
    esc_filenames=nlist();
    foreach(key;value;ARGV[0]) {
        if (exists(value['filename'])) {
            filename=escape(value['filename']);
        } else {
            filename=key;
        };
        if (exists(esc_filenames[filename])) {
            error(format("filename %s owned by more than 1 service: found service %s and %s",
                         unescape(filename), esc_filenames[filename], key));
        } else {
            esc_filenames[filename]=key;
        };
    };
    true;
};


type ${project.artifactId}_extension = extensible {};

type ${project.artifactId}_config =  {
     'mode' : long = 0644
     'owner' : string = 'root'
     'group' : string = 'root'
     'daemon' ? string[]
     'module' : string
     'backup' ? string
     'preamble' ? string
     'filename' ? string
     'contents' : ${project.artifactId}_extension
} = nlist();

type ${project.artifactId}_component = {
    include structure_component
    'services' : ${project.artifactId}_config{} with is_${project.artifactId}_services(SELF)
};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
