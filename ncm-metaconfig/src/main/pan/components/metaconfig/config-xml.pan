# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config-xml;

include { 'components/${project.artifactId}/config-common' };

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

# Embed the Quattor configuration module into XML profile.
'code' = file_contents('components/${project.artifactId}/${project.artifactId}.pm'); 
