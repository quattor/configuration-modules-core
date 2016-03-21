# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/schema;

include 'pan/types';
include 'quattor/types/component';

@{ DNS zone configuration }
type component_${project.artifactId}_dns = {
    @{subnet to use, in A.B.C.D/MASK notation}
    # TODO: look for proper type
    'subnet' ? string
    @{reverse zone (.in-addr.arpa. is added)}
    # TODO do we have a type for a apartial IP
    'reverse' ? string
    @{autoreverse determines rev from netmask, overridden by rev}
    'autoreverse' : boolean = true
};

@{ Server configuration }
type component_${project.artifactId}_server = {
    @{subnet name with DNSzone information}
    'dns' ? component_${project.artifactId}_dns{}
};

type component_${project.artifactId} = {
    include structure_component
    @{FreeIPA server that will be used for all API and for secondaries to replicate}
    'primary' : type_hostname
    @{list of secondary servers to replicate}
    'secondaries' ? type_hostname[]
    @{server configuration settings}
    'server' ? component_${project.artifactId}_server
};
