# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/schema;

include 'pan/types';
include 'quattor/types/component';

@{ service configuration }
type component_${project.artifactId}_service = {
    @{regular expressions to match known hosts; for each host, a service/host principal
      will be added and the host is allowed to retrieve the keytab}
    'hosts' ? string[]
};

@{ host configuration }
type component_${project.artifactId}_host = {
    @{host ip address (for DNS configuration only)}
    'ip_address' ? type_ipv4
    @{macaddress (for DHCP configuration only)}
    # TODO: look for proper type
    'macaddress' ? string
};

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
    @{hosts to add (not needed if installed via AII)}
    'hosts' ? component_${project.artifactId}_host{}
    @{services to add}
    'services' ? component_${project.artifactId}_service{}
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
