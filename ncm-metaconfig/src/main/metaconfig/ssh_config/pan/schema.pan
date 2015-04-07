declaration template metaconfig/ssh_config/schema;

include 'pan/types';

type ssh_config_host = {
    'ProxyCommand' ? string
    'User' ? string

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

};


type ssh_config_file = {
    'Host' ? ssh_config_host{}
    'Match' ? ssh_config_host{}
};



