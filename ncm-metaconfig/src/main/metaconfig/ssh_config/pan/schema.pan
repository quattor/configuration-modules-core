declaration template metaconfig/ssh_config/schema;

include 'pan/types';

type ssh_config_host = {
    'AddressFamily' ? string with match (SELF,"any|inet|inet6")
    'BatchMode' ? string with match (SELF, "yes|no")
    'BindAddress' ? string 
    'CanonicalDomains' ? string[] 
    'CanonicalizeFallbackLocal' ? string with match (SELF, "yes|no")
    'CanonicalizeHostname' ? string with match (SELF, "yes|no|always")
    'CanonicalizeMaxDots' ? long(0..)
    'CanonicalizePermittedCNAMEs' ? string[]
    'ChallengeResponseAuthentication' ? string with match (SELF, "yes|no")
    'CheckHostIP' ? string with match (SELF, "yes|no")
    'Cipher' ? string with match (SELF,"blowfish|3des|des")
    'Ciphers' ? string[] with match (SELF,"3des-cbc|aes128-cbc|aes192-cbc|aes256-cbc|aes128-ctr|aes192-ctr|aes256-ctr|aes128-gcm@openssh.com|aes256-gcm@openssh.com|arcfour|arcfour128|arcfour256|blowfish-cbc|cast128-cbc|chacha20-poly1305@openssh.com")
    'ClearAllForwardings' ? string with match (SELF, "yes|no")
    'Compression' ? string with match (SELF, "yes|no")
    'CompressionLevel' ? long(0..9)
    'ConnectionAttempts' ? long(0..)
    'ConnectTimeout' ? long(0..)
    'ControlMaster' ? string with match (SELF, "yes|no|ask|auto|autoask")
    'ControlPath' ? string
    'ControlPersist' ? string
    'DynamicForward' ? string
    'EnableSSHKeysign' ? string with match (SELF, "yes|no")
    'EscapeChar' ? string
    'ExitOnForwardFailure' ? string with match (SELF, "yes|no")
    'FingerprintHash'  ? string with match (SELF, "md5|sha256")
    'ForwardAgent' ? string with match (SELF, "yes|no")
    'ForwardX11' ? string with match (SELF, "yes|no")
    'ForwardX11Timeout' ? string
    'ForwardX11Trusted' ? string with match (SELF, "yes|no")
    'GatewayPorts' ? string with match (SELF, "yes|no")
    'GlobalKnownHostsFile' ? string[]
    'GSSAPIAuthentication' ? string with match (SELF, "yes|no")
    'GSSAPIDelegateCredentials' ? string with match (SELF, "yes|no")
    'HashKnownHosts' ? string with match (SELF, "yes|no")
    'HostbasedAuthentication' ? string with match (SELF, "yes|no")
    'HostbasedKeyTypes' ? string[]
    'HostKeyAlgorithms' ? string with match(SELF, "ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-rsa-cert-v01@openssh.com|ssh-dss-cert-v01@openssh.com|ecdsa-sha2-nistp256-cert-v01@openssh.com|ecdsa-sha2-nistp384-cert-v01@openssh.com|ecdsa-sha2-nistp521-cert-v01@openssh.com|ssh-rsa-cert-v00@openssh.com|ssh-dss-cert-v00@openssh.com|ssh-ed25519-cert-v01@openssh.com")
    'HostKeyAlias' ? string
    'HostName' ? string
    'IdentitiesOnly' ? string with match (SELF, "yes|no")
    'IdentityFile' ? string[]
    'IgnoreUnknown' ? string[]
    'IPQoS' ? string with match (SELF, "af11|af12|af13|af21|af22|af23|af31|af32|af33|af41|af42|af43|cs0|cs1|cs2|cs3|cs4|cs5|cs6|cs7|ef|lowdelay|throughput|reliability")
    'KbdInteractiveAuthentication' ? string with match (SELF, "yes|no")
    'KbdInteractiveDevices' ? string[] with match (SELF, "bsdauth|pam|skey")
    'KexAlgorithms' ? string[] with match (SELF, "diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1|diffie-hellman-group-exchange-sha256|ecdh-sha2-nistp256|ecdh-sha2-nistp384|ecdh-sha2-nistp521|diffie-hellman-group1-sha1|curve25519-sha256@libssh.org|gss-gex-sha1-|gss-group1-sha1-|gss-group14-sha1-")
    'LocalCommand' ? string
    'LocalForward' ? string
    'LogLevel' ? string with match (SELF, "QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG|DEBUG1|DEBUG2|DEBUG3")
    'MACs'  ? string with match(SELF, "hmac-sha1|hmac-sha1-96|hmac-sha2-256|hmac-sha2-512|hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-ripemd160@openssh.com|umac-64@openssh.com|umac-128@openssh.com|hmac-sha1-etm@openssh.com|hmac-sha1-96-etm@openssh.com|hmac-sha2-256-etm@openssh.com|hmac-sha2-512-etm@openssh.com|hmac-md5-etm@openssh.com|hmac-md5-96-etm@openssh.com|hmac-ripemd160-etm@openssh.com|umac-64-etm@openssh.com|umac-128-etm@openssh.com")
    'NoHostAuthenticationForLocalhost' ? string with match (SELF, "yes|no")
    'NumberOfPasswordPrompts' ? long(0..)
    'PasswordAuthentication' ? string with match (SELF, "yes|no")
    'PermitLocalCommand' ? string with match (SELF, "yes|no")
    'PKCS11Provider' ? string
    'Port' ? long(1..65535)
    'PreferredAuthentications' ? string[]
    'Protocol' ? long(1..2)
    'ProxyCommand' ? string
    'ProxyUseFdpass' ? string with match (SELF, "yes|no")
    'PubkeyAuthentication' ? string with match (SELF, "yes|no")
    'RekeyLimit' ? string
    'RemoteForward' ? string
    'RequestTTY' ? string with match (SELF, "yes|no|force|auto")
    'RevokedHostKeys' ? string[]
    'RhostsRSAAuthentication' ? string with match (SELF, "yes|no")
    'RSAAuthentication' ? string with match (SELF, "yes|no")
    'SendEnv' ? string[]
    'ServerAliveCountMax' ? long(0..)
    'ServerAliveInterval' ? long(0..)
    'StreamLocalBindMask' ? string
    'StreamLocalBindUnlink' ? string with match (SELF, "yes|no")
    'StrictHostKeyChecking' ? string with match (SELF, "yes|no|ask")
    'TCPKeepAlive' ? string with match (SELF, "yes|no")
    'Tunnel' ? string with match (SELF, "yes|no|point-to-point|ethernet")
    'TunnelDevice' ? string
    'UpdateHostKeys' ? string with match (SELF, "yes|no|ask")
    'UsePrivilegedPort' ? string with match (SELF, "yes|no")
    'User' ? string
    'UserKnownHostsFile' ? string[]
    'VerifyHostKeyDNS' ? string with match (SELF, "yes|no|ask")
    'VisualHostKey' ? string with match (SELF, "yes|no")
    'XAuthLocation' ? string 
};


type ssh_config_file = {
    'Host' ? ssh_config_host{}
    'Match' ? ssh_config_host{}
};



