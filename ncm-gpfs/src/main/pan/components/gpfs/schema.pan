${componentschema}

include 'quattor/types/component';
include 'pan/types';

type gpfs_curl = {
    "usecurl" ? boolean = true
    @{use kerberos token form host keytab}
    "usegss" ? boolean = false
    @{get certificate information from SINDES getcert component configuration}
    "usesindesgetcertcertwithcurl" ? boolean = false
    @{get certificate information from CCM component configuration}
    "useccmcertwithcurl" ? boolean = false
};

type gpfs_cfg = {
    include gpfs_curl
    "url" : string
    "keyData" ? string
    "sdrrestore" : boolean = false
    "subnet" : string
};

type gpfs_base = {
    include gpfs_curl
    "rpms" : string[]
    "baseurl" : string
    "useproxy" ? boolean = false
    "useyum" : boolean = true
};

type gpfs_sysmon_common = {
    'monitorinterval' ? long(0..)
    'monitoroffset' ? long(0..)
    'clockalign' ? boolean
};

type gpfs_sysmon_network = {
    include gpfs_sysmon_common
};

type gpfs_sysmon = {
    "network" ? gpfs_sysmon_network
};

type gpfs_component = {
    include structure_component
    "base" : gpfs_base
    "cfg" : gpfs_cfg
    @{GPFS mmsysmonitor configuration.
      When defined, existing configuration is read and
      only configured values are modified/added, keeping any other existing ones.}
    "sysmon" ? gpfs_sysmon
    "skiprpm" : boolean = false
};
