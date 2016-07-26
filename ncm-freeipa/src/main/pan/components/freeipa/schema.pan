# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/schema;

include 'pan/types';
include 'quattor/types/component';

@{ group members configuration }
type component_${project.artifactId}_member = {
    @{(minimal) user group members}
    'user' ? string[]
};

@{ group configuration }
type component_${project.artifactId}_group = {
    @{group ID number}
    'gidnumber' : long(0..)
    @{group members}
    'members' ? component_${project.artifactId}_member
};

@{ service configuration }
type component_${project.artifactId}_user = {
    @{user ID number}
    'uidnumber' : long(0..)
    @{last name}
    'sn' : string
    @{first name}
    'givenname' : string
    @{group name (must be a configured group to retrieve the gid)}
    'group' ? string with exists('/software/components/${project.artifactId}/server/groups/'+SELF)
    @{homedirectory}
    'homedirectory' ? string
    @{gecos}
    'gecos' ? string
    @{loginshell}
    'loginshell' ? absolute_file_path
    @{list of publick ssh keys}
    'ipasshpubkey' ? string[]
};

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
    'macaddress' ? string[]
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
    @{principal to use to perform server changes}
    'principal' : string = 'admin'
    @{subnet name with DNSzone information}
    'dns' ? component_${project.artifactId}_dns{}
    @{hosts to add (not needed if installed via AII)}
    'hosts' ? component_${project.artifactId}_host{}
    @{services to add}
    'services' ? component_${project.artifactId}_service{}
    @{users to add}
    'users' ? component_${project.artifactId}_user{}
    @{groups to add}
    'groups' ? component_${project.artifactId}_group{}
};

@{ permission / ownership for keytabs and certificates }
type component_${project.artifactId}_permission = {
    @{mode/permissions}
    'mode' : long = 0400
    @{owner}
    'owner' : string = 'root'
    @{group}
    'group' : string = 'root'
};

@{ keytab for service configuration }
type component_${project.artifactId}_keytab = {
    include component_${project.artifactId}_permission
    @{service to retrieve keytab for (the pricipal service/fqdn is used if no component is specified)}
    'service' : string
};

@{ certificate to request/retrieve. cert and/or key can be optionally extracted from NSSDB.
   permissions are set on both cert and key, with certmode for the certificate
}
type component_${project.artifactId}_certificate = {
    include component_${project.artifactId}_permission
    @{ certificate location to extract }
    'cert' ? string
    @{ certificate mode/permissions }
    'certmode' : long = 0444
    @{ (private) key location to extract }
    'key' ? string
};

# TODO: use common realm type
type component_${project.artifactId} = {
    include structure_component
    @{realm}
    'realm' : string with match(SELF, '^[a-zA-Z][\w.-]*$')
    @{FreeIPA server that will be used for all API and for secondaries to replicate}
    'primary' : type_hostname
    @{list of secondary servers to replicate}
    'secondaries' ? type_hostname[]
    @{FreeIPA domain name (defaults to /system/network/domainname value if not specified)}
    'domain' ? type_hostname
    @{server configuration settings}
    'server' ? component_${project.artifactId}_server
    @{keytabs to retrieve for services}
    'keytabs' ? component_${project.artifactId}_keytab{}
    @{certificates to request/retrieve (key is the NSSDB nick}
    'certificates' ? component_${project.artifactId}_certificate{}
    @{Generate the quattor certificate (certificate and key for host in fixed location)}
    'quattorcert' ? boolean
    @{Host options}
    'host' ? component_${project.artifactId}_host
};
