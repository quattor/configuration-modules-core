# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ssh/schema;

include 'quattor/types/component';
include 'pan/types';

type ssh_preferred_authentication = string with match(SELF, '^(gssapi-with-mic|hostbased|publickey|keyboard-interactive|password)$');

type ssh_core_options_type = {
    "AddressFamily" ? string with match (SELF, '^(any|inet6?)$')
    "ChallengeResponseAuthentication" ? legacy_binary_affirmation_string
    "Ciphers" ? string
    "Compression" ? string with match (SELF, '^(yes|delayed|no)$')
    "GSSAPIAuthentication" ? legacy_binary_affirmation_string
    "GSSAPICleanupCredentials" ? legacy_binary_affirmation_string
    "GSSAPIKeyExchange" ? legacy_binary_affirmation_string
    "GatewayPorts" ? legacy_binary_affirmation_string
    "HostbasedAuthentication" ? legacy_binary_affirmation_string
    "LogLevel" ? string with match (SELF, '^(QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG[123]?)$')
    "MACs" ? string
    "PasswordAuthentication" ? legacy_binary_affirmation_string
    "Protocol" ? string
    "PubkeyAuthentication" ? legacy_binary_affirmation_string
    "RSAAuthentication" ? legacy_binary_affirmation_string
    "RhostsRSAAuthentication" ? legacy_binary_affirmation_string
    "SendEnv" ? legacy_binary_affirmation_string
    "TCPKeepAlive" ? legacy_binary_affirmation_string
    "XAuthLocation" ? string
};

type ssh_daemon_options_type = {
    include ssh_core_options_type
    "AFSTokenPassing" ? legacy_binary_affirmation_string
    @{AcceptEnv, one per line}
    "AcceptEnv" ? string[]
    "AllowAgentForwarding" ? legacy_binary_affirmation_string
    "AllowGroups" ? string
    "AllowTcpForwarding" ? legacy_binary_affirmation_string
    "AllowUsers" ? string
    "AuthorizedKeysFile" ? string
    "AuthorizedKeysCommand" ? string
    "AuthorizedKeysCommandRunAs" ? string
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
    "NoneEnabled" ? legacy_binary_affirmation_string
    "PermitEmptyPasswords" ? legacy_binary_affirmation_string
    "PermitRootLogin" ? string with match (SELF, '^(yes|without-password|forced-commands-only|no)$')
    "PermitTunnel" ? string with match (SELF, '^(yes|point-to-point|ethernet|no)$')
    "PermitUserEnvironment" ? legacy_binary_affirmation_string
    "PidFile" ? string
    "Port" ? long
    "PrintLastLog" ? legacy_binary_affirmation_string
    "PrintMotd" ? legacy_binary_affirmation_string
    "RhostsAuthentication" ? legacy_binary_affirmation_string
    "ServerKeyBits" ? long
    "ShowPatchLevel" ? legacy_binary_affirmation_string
    "StrictModes" ? legacy_binary_affirmation_string
    "Subsystem" ? string
    "SyslogFacility" ? string with match (SELF, '^(AUTH(PRIV)?|DAEMON|USER|KERN|UUCP|NEWS|MAIL|SYSLOG|LPR|FTP|CRON|LOCAL[0-7])$')
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
