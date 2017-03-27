${componentschema}

include 'quattor/types/component';
include 'pan/types';

type cdp_component = {
    include structure_component
    @{The location of the configuration file.  Normally this should not be changed.}
    'configFile' : string = '/etc/cdp-listend.conf'
    @{The port used by the daemon.}
    'port' ? type_port
    @{The binary to execute when receiving a CDB update packet.}
    'nch' ? string
    @{The range of time delay for executing the nch executable.  The
      execution will be delayed by [0, nch_smear] seconds.}
    'nch_smear' ? long(0..)
    @{The binary to execute when receiving a CCM update packet.}
    'fetch' ? string
    @{Fetch execution offset. See explanation of fetch_smear.}
    'fetch_offset' ? long(0..)
    @{Fetch time smearing. The fetch binary will be started at a
      point in time between fetch_offset and fetch_offset + fetch_smear seconds
      after receiving a notification packet.
      The range of time delay for executing the fetch executable.  The
      execution will be delayed by [0, fetch_smear] seconds.}
    'fetch_smear' ? long(0..)
    'hostname' ? type_hostname
};
