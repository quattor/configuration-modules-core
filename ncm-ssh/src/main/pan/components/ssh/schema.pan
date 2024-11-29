# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ssh/schema;

include 'quattor/types/component';
include 'pan/types';

variable SSH_SCHEMA_VERSION ?= '5.3';

include 'components/ssh/schema-' + SSH_SCHEMA_VERSION;

type ssh_preferred_authentication = choice(
    'gssapi-with-mic',
    'hostbased',
    'keyboard-interactive',
    'password',
    'publickey'
);

type ssh_ciphers = string with is_valid_ssh_cipher(SELF);

type ssh_kexalgorithms = choice(
    'diffie-hellman-group-exchange-sha256',
    'ecdh-sha2-nistp256',
    'ecdh-sha2-nistp384',
    'ecdh-sha2-nistp521',
    'curve25519-sha256@libssh.org'
);

type ssh_MACs = string with is_valid_ssh_MAC(SELF);

type ssh_gssapikexalgorithms = choice(
    'gss-gex-sha1-',
    'gss-group1-sha1-',
    'gss-group14-sha1-',
    'gss-group14-sha256-',
    'gss-group16-sha512-',
    'gss-nistp256-sha256-',
    'gss-curve25519-sha256-'
);

function is_valid_ssh_MAC = {
    match(ARGV[0], "^(hmac-(sha2-256|sha2-512|ripemd160)|(hmac-ripemd160|umac-64|umac-128|hmac-sha2-256-etm" +
        "|hmac-sha2-512-etm|hmac-ripemd160-etm|umac-64-etm|umac-128-etm)@openssh.com)$");
};

function is_valid_ssh_cipher = {
    match (ARGV[0], "^((aes128|aes192|aes256)-ctr|(aes128-gcm|aes256-gcm|chacha20-poly1305)@openssh.com)$");
};
};

type legacy_ssh_MACs = string with {
    foreach(i; cmp; split(',', SELF)){
        if(!is_valid_ssh_MAC(cmp)){
            error("Invalid or insecure MAC found:" + cmp);
        };
    };
    true;
};

type legacy_ssh_ciphers = string with {
    foreach(i; cmp; split(',', SELF)){
        if(!is_valid_ssh_cipher(cmp)){
            error("Invalid or insecure cipher found:" + cmp);
        };
    };
    true;
};

type legacy_ssh_kexalgorithm = string with {
    foreach(i; cmp; split(',', SELF)){
        if(!is_valid_ssh_cipher(cmp)){
            error("Invalid or insecure key exchange algorithm found:" + cmp);
        };
    };
    true;
};

type ssh_core_options_type = {
    "AddressFamily" ? choice('any', 'inet', 'inet6')
    "ChallengeResponseAuthentication" ? legacy_binary_affirmation_string
    "Ciphers" ? legacy_ssh_ciphers
    "Compression" ? choice('yes', 'delayed', 'no')
    "GSSAPIAuthentication" ? legacy_binary_affirmation_string
    "GSSAPICleanupCredentials" ? legacy_binary_affirmation_string
    "GSSAPIKexAlgorithms" ? ssh_gssapikexalgorithms[1..]
    "GSSAPIKeyExchange" ? legacy_binary_affirmation_string
    "GatewayPorts" ? legacy_binary_affirmation_string
    "HostbasedAuthentication" ? legacy_binary_affirmation_string
    "LogLevel" ? choice('QUIET', 'FATAL', 'ERROR', 'INFO', 'VERBOSE', 'DEBUG1', 'DEBUG2', 'DEBUG3')
    "MACs" ? legacy_ssh_MACs
    "PasswordAuthentication" ? legacy_binary_affirmation_string
    "Protocol" ? string
    "PubkeyAuthentication" ? legacy_binary_affirmation_string
    "RSAAuthentication" ? legacy_binary_affirmation_string
    "RhostsRSAAuthentication" ? legacy_binary_affirmation_string
    "SendEnv" ? legacy_binary_affirmation_string
    "TCPKeepAlive" ? legacy_binary_affirmation_string
    "XAuthLocation" ? string
    "KexAlgorithms" ? ssh_kexalgorithms[]
};

type ssh_daemon_options_type = {
    include ssh_core_options_type
    include ssh_authkeyscommand_options_type
    "AFSTokenPassing" ? legacy_binary_affirmation_string
    @{AcceptEnv, one per line}
    "AcceptEnv" ? string[]
    "AllowAgentForwarding" ? legacy_binary_affirmation_string
    "AllowGroups" ? string
    "AllowTcpForwarding" ? choice('yes', 'no', 'all', 'local', 'remote')
    "AllowUsers" ? string
    "AuthorizedKeysFile" ? string
    "Banner" ? string
    "ClientAliveCountMax" ? long
    "ClientAliveInterval" ? long
    "DenyGroups" ? string
    "DenyUsers" ? string
    "GSSAPIStrictAcceptorCheck" ? legacy_binary_affirmation_string
    @{HostKey, one per line}
    "HostKey" ? string[]
    "HPNDisabled" ? legacy_binary_affirmation_string
    "HPNBufferSize" ? long
    "IgnoreRhosts" ? legacy_binary_affirmation_string
    "IgnoreUserKnownHosts" ? legacy_binary_affirmation_string
    "KbdInteractiveAuthentication" ? legacy_binary_affirmation_string
    "KerberosAuthentication" ? legacy_binary_affirmation_string
    "KerberosGetAFSToken" ? legacy_binary_affirmation_string
    "KerberosOrLocalPasswd" ? legacy_binary_affirmation_string
    "KerberosTgtPassing" ? legacy_binary_affirmation_string
    "KerberosTicketAuthentication" ? legacy_binary_affirmation_string
    "KerberosTicketCleanup" ? legacy_binary_affirmation_string
    "KeyRegenerationInterval" ? long
    @{ListenAddress, one per line}
    "ListenAddress" ? type_hostport[]
    "LoginGraceTime" ? long
    "MaxAuthTries" ? long
    "MaxStartups" ? long
    "MaxSessions" ? long(0..)
    "NoneEnabled" ? legacy_binary_affirmation_string
    "PermitEmptyPasswords" ? legacy_binary_affirmation_string
    "PermitRootLogin" ? choice(
        'yes',
        'prohibit-password',
        'without-password',
        'forced-commands-only',
        'no'
    ) with {
        if (SELF == 'without-password') {
            deprecated(0, '"without-password" is deprecated and should be updated to "prohibit-password"');
        };
        true;
    }
    "PermitTunnel" ? choice('yes', 'point-to-point', 'ethernet', 'no')
    "PermitUserEnvironment" ? legacy_binary_affirmation_string
    "PidFile" ? string
    "Port" ? long
    "PrintLastLog" ? legacy_binary_affirmation_string
    "PrintMotd" ? legacy_binary_affirmation_string
    "RevokedKeys" ? string with {
        if(!((SELF == 'none' ) || is_absolute_file_path(SELF))) {
            error("RevokedKeys must either be a file path or none")
        };
        true;
    }
    "RhostsAuthentication" ? legacy_binary_affirmation_string
    "ServerKeyBits" ? long
    "ShowPatchLevel" ? legacy_binary_affirmation_string
    "StrictModes" ? legacy_binary_affirmation_string
    "Subsystem" ? string
    "SyslogFacility" ? string with match (SELF,
        '^(AUTH(PRIV)?|DAEMON|USER|KERN|UUCP|NEWS|MAIL|SYSLOG|LPR|FTP|CRON|LOCAL[0-7])$'
    )
    "TcpRcvBuf" ? long
    "TcpRcvBufPoll" ? legacy_binary_affirmation_string
    "UseDNS" ? legacy_binary_affirmation_string
    "UseLogin" ? legacy_binary_affirmation_string
    "UsePAM" ? legacy_binary_affirmation_string
    "UsePrivilegeSeparation" ? legacy_binary_affirmation_string
    "VerifyReverseMapping" ? legacy_binary_affirmation_string
    "X11DisplayOffset" ? long
    "X11Forwarding" ? legacy_binary_affirmation_string
    "X11UseLocalhost" ? legacy_binary_affirmation_string
};

type ssh_client_options_type = {
    include ssh_core_options_type
    "BatchMode" ? legacy_binary_affirmation_string
    "ConnectTimeout" ? long
    "EnableSSHKeysign" ? legacy_binary_affirmation_string
    "ForwardAgent" ? legacy_binary_affirmation_string
    "ForwardX11" ? legacy_binary_affirmation_string
    "HashKnownHosts" ? legacy_binary_affirmation_string
    "GSSAPIDelegateCredentials" ? legacy_binary_affirmation_string
    "Port" ? long
    "PreferredAuthentications" ? ssh_preferred_authentication[]
    "RhostsAuthentication" ? legacy_binary_affirmation_string
    "StrictHostKeyChecking" ? legacy_binary_affirmation_string
    "UsePrivilegedPort" ? legacy_binary_affirmation_string
};

type ssh_daemon_type = {
    "options" ? ssh_daemon_options_type
    "comment_options" ? ssh_daemon_options_type
    "sshd_path" ? string
    @{if false and sshd doesn't exist, skip config validation}
    "always_validate" : boolean = true
    "config_path" ? string
};

type ssh_client_type = {
    "options" ? ssh_client_options_type
    "comment_options" ? ssh_client_options_type
    "config_path" ? string
};

type component_ssh_type = {
    include structure_component
    "daemon" ? ssh_daemon_type
    "client" ? ssh_client_type
};

bind "/software/components/ssh" = component_ssh_type;
