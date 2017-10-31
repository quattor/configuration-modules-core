declaration template metaconfig/ssh/schema;

include 'pan/types';

include 'components/ssh/schema';

type ssh_config_opts = {
    'AddressFamily' ? string with match (SELF, "^(any|inet|inet6)$")
    'BatchMode' ? boolean
    'BindAddress' ? string
    'CanonicalDomains' ? string[]
    'CanonicalizeFallbackLocal' ? boolean
    'CanonicalizeHostname' ? string with match (SELF, "^(yes|no|always)$")
    'CanonicalizeMaxDots' ? long(0..)
    'CanonicalizePermittedCNAMEs' ? string[]
    'ChallengeResponseAuthentication' ? boolean
    'CheckHostIP' ? boolean
    'Cipher' ? string with match (SELF, "^(blowfish|3des|des)$")
    'Ciphers' ? ssh_ciphers[]
    'ClearAllForwardings' ? boolean
    'Compression' ? boolean
    'CompressionLevel' ? long(0..9)
    'ConnectionAttempts' ? long(0..)
    'ConnectTimeout' ? long(0..)
    'ControlMaster' ? string with match (SELF, "^(yes|no|ask|auto|autoask)$")
    'ControlPath' ? string
    'ControlPersist' ? string
    'DynamicForward' ? string
    'EnableSSHKeysign' ? boolean
    'EscapeChar' ? string
    'ExitOnForwardFailure' ? boolean
    'FingerprintHash' ? string with match (SELF, "^(md5|sha256)$")
    'ForwardAgent' ? boolean
    'ForwardX11' ? boolean
    'ForwardX11Timeout' ? long(0..)
    'ForwardX11Trusted' ? boolean
    'GatewayPorts' ? boolean
    'GlobalKnownHostsFile' ? string[]
    'GSSAPIAuthentication' ? boolean
    'GSSAPIDelegateCredentials' ? boolean
    'HashKnownHosts' ? boolean
    'HostbasedAuthentication' ? boolean
    'HostbasedKeyTypes' ? string[]
    'HostKeyAlgorithms' ? ssh_hostkeyalgorithms[]
    'HostKeyAlias' ? string
    'HostName' ? string
    'IdentitiesOnly' ? boolean
    'IdentityFile' ? string[]
    'IgnoreUnknown' ? string[]
    'IPQoS' ? string with match (SELF, "^(af[1234][123]|cs[0-7]|ef|lowdelay|throughput|reliability)$")
    'KbdInteractiveAuthentication' ? boolean
    'KbdInteractiveDevices' ? ssh_kbdinteractivedevices[]
    'KexAlgorithms' ? ssh_kexalgorithms[]
    'LocalCommand' ? string
    'LocalForward' ? string
    'LogLevel' ? string with match (SELF, "^(QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG|DEBUG[123])$")
    'MACs' ? ssh_MACs[]
    'NoHostAuthenticationForLocalhost' ? boolean
    'NumberOfPasswordPrompts' ? long(0..)
    'PasswordAuthentication' ? boolean
    'PermitLocalCommand' ? boolean
    'PKCS11Provider' ? string
    'Port' ? long(1..65535)
    'PreferredAuthentications' ? string[]
    'Protocol' ? long(1..2)
    'ProxyCommand' ? string
    'ProxyUseFdpass' ? boolean
    'PubkeyAuthentication' ? boolean
    'RekeyLimit' ? string
    'RemoteForward' ? string
    'RequestTTY' ? string with match (SELF, "^(yes|no|force|auto)$")
    'RevokedHostKeys' ? string[]
    'RhostsRSAAuthentication' ? boolean
    'RSAAuthentication' ? boolean
    'SendEnv' ? string[]
    'ServerAliveCountMax' ? long(0..)
    'ServerAliveInterval' ? long(0..)
    'StreamLocalBindMask' ? string
    'StreamLocalBindUnlink' ? boolean
    'StrictHostKeyChecking' ? string with match (SELF, "^(yes|no|ask)$")
    'TCPKeepAlive' ? boolean
    'Tunnel' ? string with match (SELF, "^(yes|no|point-to-point|ethernet)$")
    'TunnelDevice' ? string
    'UpdateHostKeys' ? string with match (SELF, "^(yes|no|ask)$")
    'UsePrivilegedPort' ? boolean
    'User' ? string
    'UserKnownHostsFile' ? string[]
    'VerifyHostKeyDNS' ? string with match (SELF, "^(yes|no|ask)$")
    'VisualHostKey' ? boolean
    'XAuthLocation' ? string
};

type ssh_config_host = {
    "hostnames" : string[]
    include ssh_config_opts

};

type ssh_config_match = {
    "matches" : string[]
    include ssh_config_opts

};

type ssh_config_file = {
    'Host' ? ssh_config_host[]
    'Match' ? ssh_config_match[]
    'main' ? ssh_config_opts
};

