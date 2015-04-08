declaration template metaconfig/ssh_config/schema;

include 'pan/types';

type ssh_ciphers = string with match (SELF, "^(3des-cbc|aes128-cbc|aes192-cbc|aes256-cbc|aes128-ctr|aes192-ctr|aes256-ctr|aes128-gcm@openssh.com|aes256-gcm@openssh.com|arcfour|arcfour128|arcfour256|blowfish-cbc|cast128-cbc|chacha20-poly1305@openssh.com)$"); 
type ssh_hostkeyalgorithms = string with match(SELF, "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-rsa-cert-v01@openssh.com|ssh-dss-cert-v01@openssh.com|ecdsa-sha2-nistp256-cert-v01@openssh.com|ecdsa-sha2-nistp384-cert-v01@openssh.com|ecdsa-sha2-nistp521-cert-v01@openssh.com|ssh-rsa-cert-v00@openssh.com|ssh-dss-cert-v00@openssh.com|ssh-ed25519-cert-v01@openssh.com)$");
type ssh_kbdinteractivedevices = string with match (SELF, "^(bsdauth|pam|skey)$");
type ssh_kexalgorithms = string with match (SELF, "^(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1|diffie-hellman-group-exchange-sha256|ecdh-sha2-nistp256|ecdh-sha2-nistp384|ecdh-sha2-nistp521|diffie-hellman-group1-sha1|curve25519-sha256@libssh.org|gss-gex-sha1-|gss-group1-sha1-|gss-group14-sha1-)$");
type ssh_MACs = string with match(SELF, "^(hmac-sha1|hmac-sha1-96|hmac-sha2-256|hmac-sha2-512|hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-ripemd160@openssh.com|umac-64@openssh.com|umac-128@openssh.com|hmac-sha1-etm@openssh.com|hmac-sha1-96-etm@openssh.com|hmac-sha2-256-etm@openssh.com|hmac-sha2-512-etm@openssh.com|hmac-md5-etm@openssh.com|hmac-md5-96-etm@openssh.com|hmac-ripemd160-etm@openssh.com|umac-64-etm@openssh.com|umac-128-etm@openssh.com)$");


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
    'FingerprintHash'  ? string with match (SELF, "^(md5|sha256)$")
    'ForwardAgent' ? boolean
    'ForwardX11' ? boolean
    'ForwardX11Timeout' ? string
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
    'IPQoS' ? string with match (SELF, "^(af11|af12|af13|af21|af22|af23|af31|af32|af33|af41|af42|af43|cs0|cs1|cs2|cs3|cs4|cs5|cs6|cs7|ef|lowdelay|throughput|reliability)$")
    'KbdInteractiveAuthentication' ? boolean
    'KbdInteractiveDevices' ? ssh_kbdinteractivedevices[]
    'KexAlgorithms' ?  ssh_kexalgorithms[]
    'LocalCommand' ? string
    'LocalForward' ? string
    'LogLevel' ? string with match (SELF, "^(QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG|DEBUG1|DEBUG2|DEBUG3)$")
    'MACs'  ? ssh_MACs[]
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

