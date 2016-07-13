# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/${project.artifactId}/schema;

include 'quattor/types/component';

type component_nss_build = {
    "script" : string
    "depends" ? string
    "active" ? boolean
};

type component_nss_build_dbs = {
    "db" ? component_nss_build
    "nis" ? component_nss_build
    "compat" ? component_nss_build
    "dns" ? component_nss_build
    "files" ? component_nss_build
    "ldap" ? component_nss_build
};

type component_nss_db = string[];

type component_${project.artifactId}_type = {
    include structure_component
    "build" ? component_nss_build_dbs
    "databases" : component_nss_db{}
};

bind "/software/components/${project.artifactId}" = component_${project.artifactId}_type;

