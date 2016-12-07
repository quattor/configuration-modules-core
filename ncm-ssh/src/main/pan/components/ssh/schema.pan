# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ssh/schema;

include 'quattor/types/component';
include 'pan/types';

type ssh_preferred_authentication = string with match(SELF, '^(gssapi-with-mic|hostbased|publickey|keyboard-interactive|password)$');

type ssh_ciphers = string with is_valid_ssh_cipher(SELF);
type ssh_hostkeyalgorithms = string with match(SELF, "^(ssh-(rsa|dss|ed25519)|ecdsa-sha2-nistp(256|384|521)|(ssh-rsa-cert-v01|ssh-dss-cert-v01|ecdsa-sha2-nistp256-cert-v01|ecdsa-sha2-nistp384-cert-v01|ecdsa-sha2-nistp521-cert-v01|ssh-rsa-cert-v00|ssh-dss-cert-v00|ssh-ed25519-cert-v01)@openssh.com)$");
type ssh_kbdinteractivedevices = string with match (SELF, "^(bsdauth|pam|skey)$");
type ssh_kexalgorithms = string with match (SELF, "^(diffie-hellman-group-exchange-sha256|ecdh-sha2-nistp(256|384|521)|curve25519-sha256@libssh.org)$");
type ssh_MACs = string with is_valid_ssh_MAC(SELF);

function is_valid_ssh_MAC = {
    match(ARGV[0], "^(hmac-(sha1|sha2-256|sha2-512|ripemd160)|(hmac-ripemd160|umac-64|umac-128|hmac-sha1-etm|hmac-sha2-256-etm|hmac-sha2-512-etm|hmac-ripemd160-etm|umac-64-etm|umac-128-etm)@openssh.com)$");
};

function is_valid_ssh_cipher = {
    match (ARGV[0], "^((aes128|aes192|aes256)-ctr|(aes128-gcm|aes256-gcm|chacha20-poly1305)@openssh.com)$");
};

function is_valid_ssh_kexalgorithm = {
    match (ARGV[0], "^(diffie-hellman-group-exchange-sha256|ecdh-sha2-nistp(256|384|521)|curve25519-sha256@libssh.org)$");
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
    "AddressFamily"                     ? string with match (SELF, '^(any|inet6?)$')
    "ChallengeResponseAuthentication"   ? legacy_binary_affirmation_string
    "Ciphers"                           ? legacy_ssh_ciphers
    "Compression"                       ? string with match (SELF, '^(yes|delayed|no)$')
    "GSSAPIAuthentication"              ? legacy_binary_affirmation_string
    "GSSAPICleanupCredentials"          ? legacy_binary_affirmation_string
    "GSSAPIKeyExchange"                 ? legacy_binary_affirmation_string
    "GatewayPorts"                      ? legacy_binary_affirmation_string
    "HostbasedAuthentication"           ? legacy_binary_affirmation_string
    "LogLevel"                          ? string with match (SELF, '^(QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG[123]?)$')
    "MACs"                              ? legacy_ssh_MACs
    "PasswordAuthentication"            ? legacy_binary_affirmation_string
    "Protocol"                          ? string
    "PubkeyAuthentication"              ? legacy_binary_affirmation_string
    "RSAAuthentication"                 ? legacy_binary_affirmation_string
    "RhostsRSAAuthentication"           ? legacy_binary_affirmation_string
    "SendEnv"                           ? legacy_binary_affirmation_string
    "TCPKeepAlive"                      ? legacy_binary_affirmation_string
    "XAuthLocation"                     ? string
    "KexAlgorithms"						? ssh_kexalgorithms[]
};

type ssh_daemon_options_type = {
    include ssh_core_options_type
    "AFSTokenPassing"                   ? legacy_binary_affirmation_string
    @{AcceptEnv, one per line}
    "AcceptEnv"                         ? string[]
    "AllowAgentForwarding"              ? legacy_binary_affirmation_string
    "AllowGroups"                       ? string
    "AllowTcpForwarding"                ? legacy_binary_affirmation_string
    "AllowUsers"                        ? string
    "AuthorizedKeysFile"                ? string
    "AuthorizedKeysCommand"             ? string
    "AuthorizedKeysCommandRunAs"        ? string
    "Banner"                            ? string
    "ClientAliveCountMax"               ? long
    "ClientAliveInterval"               ? long
    "DenyGroups"                        ? string
    "DenyUsers"                         ? string
    "GSSAPIStrictAcceptorCheck"         ? legacy_binary_affirmation_string
    @{HostKey, one per line}
    "HostKey"                           ? string[]
    "HPNDisabled"                       ? legacy_binary_affirmation_string
    "HPNBufferSize"                     ? long
    "IgnoreRhosts"                      ? legacy_binary_affirmation_string
    "IgnoreUserKnownHosts"              ? legacy_binary_affirmation_string
    "KbdInteractiveAuthentication"      ? legacy_binary_affirmation_string
    "KerberosAuthentication"            ? legacy_binary_affirmation_string
    "KerberosGetAFSToken"               ? legacy_binary_affirmation_string
    "KerberosOrLocalPasswd"             ? legacy_binary_affirmation_string
    "KerberosTgtPassing"                ? legacy_binary_affirmation_string
    "KerberosTicketAuthentication"      ? legacy_binary_affirmation_string
    "KerberosTicketCleanup"             ? legacy_binary_affirmation_string
    "KeyRegenerationInterval"           ? long
    @{ListenAddress, one per line}
    "ListenAddress"                     ? type_hostport[]
    "LoginGraceTime"                    ? long
    "MaxAuthTries"                      ? long
    "MaxStartups"                       ? long
    "NoneEnabled"                       ? legacy_binary_affirmation_string
    "PermitEmptyPasswords"              ? legacy_binary_affirmation_string
    "PermitRootLogin"                   ? string with match (SELF, '^(yes|without-password|forced-commands-only|no)$')
    "PermitTunnel"                      ? string with match (SELF, '^(yes|point-to-point|ethernet|no)$')
    "PermitUserEnvironment"             ? legacy_binary_affirmation_string
    "PidFile"                           ? string
    "Port"                              ? long
    "PrintLastLog"                      ? legacy_binary_affirmation_string
    "PrintMotd"                         ? legacy_binary_affirmation_string
    "RhostsAuthentication"              ? legacy_binary_affirmation_string
    "ServerKeyBits"                     ? long
    "ShowPatchLevel"                    ? legacy_binary_affirmation_string
    "StrictModes"                       ? legacy_binary_affirmation_string
    "Subsystem"                         ? string
    "SyslogFacility"                    ? string with match (SELF, '^(AUTH(PRIV)?|DAEMON|USER|KERN|UUCP|NEWS|MAIL|SYSLOG|LPR|FTP|CRON|LOCAL[0-7])$')
    "TcpRcvBuf"                         ? long
    "TcpRcvBufPoll"                     ? legacy_binary_affirmation_string
    "UseDNS"                            ? legacy_binary_affirmation_string
    "UseLogin"                          ? legacy_binary_affirmation_string
    "UsePAM"                            ? legacy_binary_affirmation_string
    "UsePrivilegeSeparation"            ? legacy_binary_affirmation_string
    "VerifyReverseMapping"              ? legacy_binary_affirmation_string
    "X11DisplayOffset"                  ? long
    "X11Forwarding"                     ? legacy_binary_affirmation_string
    "X11UseLocalhost"                   ? legacy_binary_affirmation_string
};

type ssh_client_options_type = {
    include ssh_core_options_type
    "BatchMode"                         ? legacy_binary_affirmation_string
    "ConnectTimeout"                    ? long
    "EnableSSHKeysign"                  ? legacy_binary_affirmation_string
    "ForwardAgent"                      ? legacy_binary_affirmation_string
    "ForwardX11"                        ? legacy_binary_affirmation_string
    "GSSAPIDelegateCredentials"         ? legacy_binary_affirmation_string
    "Port"                              ? long
    "PreferredAuthentications"          ? ssh_preferred_authentication[]
    "RhostsAuthentication"              ? legacy_binary_affirmation_string
    "StrictHostKeyChecking"             ? legacy_binary_affirmation_string
    "UsePrivilegedPort"                 ? legacy_binary_affirmation_string
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
