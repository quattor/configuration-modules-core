declaration template metaconfig/ssh/schema;

include 'pan/types';

# rename these types to prevent conflicts
#   we will remove these in an upcoming pr after template-library-core
#   has been updated with the new types from ncm-ssh
type temp_ssh_ciphers = string with match (SELF, "^[+-]?(" +
    "(blowfish|3des|aes(128|192|256)|cast128)-cbc" +
    "|aes(128|192|256)-ctr|arcfour|arcfour(128|256)" +
    "|(aes(128|256)-gcm|chacha20-poly1305)@openssh.com)$");
type temp_ssh_hostkeyalgorithms = string with match(SELF, "^[+-]?(" +
    "ssh-(rsa|dss|ed25519)|ecdsa-sha2-nistp(256|384|521)|" +
    "(ssh-rsa-cert-v0[01]|ssh-dss-cert-v01|ecdsa-sha2-nistp(256|384|521)-cert-v01|" +
    "ssh-dss-cert-v00|ssh-ed25519-cert-v01)@openssh.com)$");
type temp_ssh_kbdinteractivedevices = string with match (SELF, "^(bsdauth|pam|skey)$");
# Recent versions have distinct GSSAPIKexAlgorithms
type temp_ssh_gss_kexalgorithms = string with match (SELF, "^[+-]?(gss-(gex|group1|group14)-sha1-" +
    "|gss-group14-sha256-|gss-group16-sha512-|gss-nistp256-sha256-|gss-curve25519-sha256-)$");
# Older versions include GSSAPI mechanisms in KEXAlgorithms, but only the SHA1 variants
type temp_ssh_kexalgorithms = string with match (SELF, "^[+-]?(" +
    "diffie-hellman-group(1-sha1|14-sha1|-exchange-sha1|-exchange-sha256)" +
    "|ecdh-sha2-nistp(256|384|521)|curve25519-sha256@libssh.org" +
    "|gss-(gex|group1|group14)-sha1-)$");
type temp_ssh_MACs = string with match(SELF, "^[+-]?(hmac-(sha1|sha1-96|sha2-256|sha2-512|md5|md5-96|ripemd160)|" +
    "(hmac-ripemd160|umac-64|umac-128|hmac-sha1-etm|hmac-sha1-96-etm|hmac-sha2-256-etm|hmac-sha2-512-etm|" +
    "hmac-md5-etm|hmac-md5-96-etm|hmac-ripemd160-etm|umac-64-etm|umac-128-etm)@openssh.com)$");
type temp_ssh_CAAlgorithms = string with match(SELF, "^[+-]?(" +
    "ecdsa-sha2-nistp(256|384|521)|ssh-ed25519|rsa-sha2-(256|512)|ssh-rsa)$");


type ssh_config_opts = {
    'AddKeysToAgent' ? string with match (SELF, "^(yes|no|ask|confirm)$")
    'AddressFamily' ? string with match (SELF, "^(any|inet|inet6)$")
    'BatchMode' ? boolean
    'BindAddress' ? string
    'BindInterface' ? string
    'CanonicalDomains' ? string[]
    'CanonicalizeFallbackLocal' ? boolean
    'CanonicalizeHostname' ? string with match (SELF, "^(yes|no|always)$")
    'CanonicalizeMaxDots' ? long(0..)
    'CanonicalizePermittedCNAMEs' ? string[]
    'CASignatureAlgorithms' ? temp_ssh_CAAlgorithms[]
    'CertificateFile' ? string[]
    'ChallengeResponseAuthentication' ? boolean
    'CheckHostIP' ? boolean
    'Cipher' ? string with match (SELF, "^(blowfish|3des|des)$")
    'Ciphers' ? temp_ssh_ciphers[]
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
    'GSSAPIClientIdentity' ? string
    'GSSAPIDelegateCredentials' ? boolean
    'GSSAPIKeyExchange' ? boolean
    'GSSAPIKexAlgorithms' ? temp_ssh_gss_kexalgorithms[]
    'GSSAPIRenewalForcesRekey' ? boolean
    'GSSAPIServerIdentity' ? string
    'GSSAPITrustDns' ? boolean
    'HashKnownHosts' ? boolean
    'HostbasedAuthentication' ? boolean
    'HostbasedKeyTypes' ? string[]
    'HostKeyAlgorithms' ? temp_ssh_hostkeyalgorithms[]
    'HostKeyAlias' ? string
    'HostName' ? string
    'IdentitiesOnly' ? boolean
    'IdentityAgent' ? string
    'IdentityFile' ? string[]
    'IgnoreUnknown' ? string[]
    'Include' ? string[]
    'IPQoS' ? string with match (SELF, "^(af[1234][123]|cs[0-7]|ef|lowdelay|throughput|reliability)$")
    'KbdInteractiveAuthentication' ? boolean
    'KbdInteractiveDevices' ? temp_ssh_kbdinteractivedevices[]
    'KexAlgorithms' ? temp_ssh_kexalgorithms[]
    'LocalCommand' ? string
    'LocalForward' ? string
    'LogLevel' ? string with match (SELF, "^(QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG|DEBUG[123])$")
    'MACs' ? temp_ssh_MACs[]
    'NoHostAuthenticationForLocalhost' ? boolean
    'NumberOfPasswordPrompts' ? long(0..)
    'PasswordAuthentication' ? boolean
    'PermitLocalCommand' ? boolean
    'PKCS11Provider' ? string
    'Port' ? long(1..65535)
    'PreferredAuthentications' ? string[]
    'Protocol' ? long(1..2)
    'ProxyCommand' ? string
    'ProxyJump' ? string[]
    'ProxyUseFdpass' ? boolean
    'PubkeyAcceptedKeyTypes' ? temp_ssh_hostkeyalgorithms[]
    'PubkeyAuthentication' ? boolean
    'RekeyLimit' ? string
    'RemoteCommand' ? string
    'RemoteForward' ? string
    'RequestTTY' ? string with match (SELF, "^(yes|no|force|auto)$")
    'RevokedHostKeys' ? string[]
    'RhostsRSAAuthentication' ? boolean
    'RSAAuthentication' ? boolean
    'SendEnv' ? string[]
    'ServerAliveCountMax' ? long(0..)
    'ServerAliveInterval' ? long(0..)
    'SetEnv' ? string{}
    'StreamLocalBindMask' ? string
    'StreamLocalBindUnlink' ? boolean
    'StrictHostKeyChecking' ? string with match (SELF, "^(yes|no|ask)$")
    'SyslogFacility' ? string with match(SELF, "^(DAEMON|USER|AUTH(PRIV)?|LOCAL[0-7])$")
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

type ssh_config_match_criteria = {
    "all" ? boolean with SELF
    "canonical" ? boolean with SELF
    "final" ? boolean with SELF
    "user" ? string[]
    "localuser" ? string[]
    "host" ? string[]
    "originalhost" ? string[]
    "exec" ? string
} with {
    if (exists(SELF['all']) && length(SELF) > 1) {
        error('You can only set all, no other options allowed');
    };
    true;
};

type ssh_config_match = {
    "criteria" : ssh_config_match_criteria with length(SELF) > 0
    include ssh_config_opts
};

type ssh_config_file = {
    'Host' ? ssh_config_host[]
    'Match' ? ssh_config_match[]
    'main' ? ssh_config_opts
};

# Not all options may appear inside a Match block
type sshd_config_match_opts = {
    'AcceptEnv' ? string[]
    'AllowAgentForwarding' ? boolean
    'AllowGroups' ? string[]
    'AllowStreamLocalForwarding' ? string with match (SELF, "^(yes|all|no|local|remote)$")
    'AllowTcpForwarding' ? string with match (SELF, "^(yes|all|no|local|remote)$")
    'AllowUsers' ? string[]
    'AuthenticationMethods' ? string[] # Don't go into details - it does not seem to worth the effort
    'AuthorizedKeysCommand' ? absolute_file_path
    'AuthorizedKeysCommandUser' ? string
    'AuthorizedKeysFile' ? string[]
    'AuthorizedPrincipalsCommand' ? absolute_file_path
    'AuthorizedPrincipalsCommandUser' ? string
    'AuthorizedPrincipalsFile' ? string[]
    'Banner' ? string
    'ChrootDirectory' ? string
    'ClientAliveCountMax' ? long(1..)
    'ClientAliveInterval' ? long(0..)
    'DenyGroups' ? string[]
    'DenyUsers' ? string[]
    'ForceCommand' ? string
    'GatewayPorts' ? string with match (SELF, "^(yes|no|clientspecified)$")
    'GSSAPIAuthentication' ? boolean
    'HostbasedAcceptedKeyTypes' ? temp_ssh_hostkeyalgorithms[]
    'HostbasedAuthentication' ? boolean
    'HostbasedUsesNameFromPacketOnly' ? boolean
    'IPQoS' ? string[] with length(SELF) == 1 || length(SELF) == 2
    'KbdInteractiveAuthentication' ? boolean
    'KerberosAuthentication' ? boolean
    'LogLevel' ? string with match (SELF, "^(QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG[123]?)$")
    'MaxAuthTries' ? long(1..)
    'MaxSessions' ? long(0..)
    'PasswordAuthentication' ? boolean
    'PermitEmptyPasswords' ? boolean
    'PermitListen' ? string[] # type_hostport would not allow wildcards
    'PermitOpen' ? string[] # type_hostport would not allow wildcards
    'PermitRootLogin' ? string with match (SELF, "^(yes|prohibit-password|without-password|forced-commands-only|no)$")
    'PermitTTY' ? boolean
    'PermitTunnel' ? string with match (SELF, "^(yes|point-to-point|ethernet|no)$")
    'PermitUserRC' ? boolean
    'PubkeyAcceptedKeyTypes' ? temp_ssh_hostkeyalgorithms[]
    'PubkeyAuthentication' ? boolean
    'RekeyLimit' ? string[] with length(SELF) == 1 || length(SELF) == 2
    'RSAAuthentication' ? boolean
    'RhostsRSAAuthentication' ? boolean
    'RevokedKeys' ? string
    'RDomain' ? string
    'SetEnv' ? string{}
    'StreamLocalBindMask' ? string with match (SELF, "^[0-7]{3,5}$")
    'StreamLocalBindUnlink' ? boolean
    'TrustedUserCAKeys' ? string
    'X11DisplayOffset' ? long(0..)
    'X11Forwarding' ? boolean
    'X11UseLocalHost' ? boolean
};

type sshd_config_match_criteria = {
    "All" ? boolean with SELF
    "User" ? string[]
    "Group" ? string[]
    "Host" ? string[]
    "LocalAddress" ? string[]
    "LocalPort" ? string[]
    "RDomain" ? string[]
    "Address" ? string[]
} with {
    if (exists(SELF['All']) && length(SELF) > 1) {
        error('You can only set All, no other options allowed');
    };
    true;
};

type sshd_config_match = {
    "criteria" : sshd_config_match_criteria with length(SELF) > 0
    include sshd_config_match_opts
};

type sshd_config_opts = {
    include sshd_config_match_opts
    'AddressFamily' ? string with match (SELF, "^(any|inet|inet6)$")
    'CASignatureAlgorithms' ? temp_ssh_CAAlgorithms[]
    'ChallengeResponseAuthentication' ? boolean
    'Ciphers' ? temp_ssh_ciphers[]
    'Compression' ? boolean
    'DisableForwarding' ? boolean
    'ExposeAuthInfo' ? boolean
    'FingerprintHash' ? string with match (SELF, "^(md5|sha256)$")
    'GSSAPICleanupCredentials' ? boolean
    'GSSAPIKeyExchange' ? boolean
    'GSSAPIKexAlgorithms' ? temp_ssh_gss_kexalgorithms[]
    'GSSAPIStrictAcceptorCheck' ? boolean
    'GSSAPIStoreCredentialsOnRekey' ? boolean
    'HostCertificate' ? string
    'HostKey' ? string[]
    'HostKeyAgent' ? string
    'HostKeyAlgorithms' ? temp_ssh_hostkeyalgorithms[]
    'IgnoreRhosts' ? boolean
    'IgnoreUserKnownHosts' ? boolean
    'KerberosGetAFSToken' ? boolean
    'KerberosOrLocalPasswd' ? boolean
    'KerberosTicketCleanup' ? boolean
    'KexAlgorithms' ? temp_ssh_kexalgorithms[]
    'ListenAddress' ? type_hostport[]
    'LoginGraceTime' ? long(0..)
    'MACs' ? temp_ssh_MACs[]
    'Match' ? sshd_config_match[]
    'MaxStartups' ? string with match (SELF, "^[0-9]+(:[0-9]+:[0-9]+)?$")
    'PermitUserEnvironment' ? boolean
    'PidFile' ? absolute_file_path
    'Port' ? long(1..)[]
    'PrintLastLog' ? boolean
    'PrintMotd' ? boolean
    'StrictModes' ? boolean
    'Subsystem' ? string{}
    'SyslogFacility' ? string with match (SELF, "^(DAEMON|USER|AUTH|LOCAL[0-7])$")
    'TCPKeepAlive' ? boolean
    'UseDNS' ? boolean
    'UsePAM' ? boolean
    'VersionAddendum' ? string
    'XAuthLocation' ? absolute_file_path
};

type sshd_config_file = {
    'Match' ? sshd_config_match[]
    'main' ? sshd_config_opts
};
