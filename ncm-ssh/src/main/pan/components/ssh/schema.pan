# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ssh/schema;

include { 'quattor/schema' };

type ssh_core_options_type = {
    "AddressFamily"                     ? string with match (SELF, 'any|inet|inet6')
    "ChallengeResponseAuthentication"   ? string with match (SELF, 'yes|no')
    "Ciphers"                           ? string
    "Compression"                       ? string with match (SELF, 'yes|delayed|no')
    "GSSAPIAuthentication"              ? string with match (SELF, 'yes|no')
    "GSSAPICleanupCredentials"          ? string with match (SELF, 'yes|no')
    "GatewayPorts"                      ? string with match (SELF, 'yes|no')
    "HostbasedAuthentication"           ? string with match (SELF, 'yes|no')
    "LogLevel"                          ? string with match (SELF, 'DEBUG|INFO|NOTICE|WARNING|ERR|CRIT|ALERT|EMERG')
    "MACs"                              ? string
    "PasswordAuthentication"            ? string with match (SELF, 'yes|no')
    "Protocol"                          ? string
    "PubkeyAuthentication"              ? string with match (SELF, 'yes|no')
    "RSAAuthentication"                 ? string with match (SELF, 'yes|no')
    "RhostsRSAAuthentication"           ? string with match (SELF, 'yes|no')
    "SendEnv"                           ? string with match (SELF, 'yes|no')
    "TCPKeepAlive"                      ? string with match (SELF, 'yes|no')
    "XAuthLocation"                     ? string
};

type ssh_daemon_options_type = {
    include ssh_core_options_type
    "AFSTokenPassing"                   ? string with match (SELF, 'yes|no')
    "AcceptEnv"                         ? string with match (SELF, 'yes|no')
    "AllowGroups"                       ? string
    "AllowTcpForwarding"                ? string with match (SELF, 'yes|no')
    "AllowUsers"                        ? string
    "AuthorizedKeysFile"                ? string
    "Banner"                            ? string
    "ClientAliveCountMax"               ? long
    "ClientAliveInterval"               ? long
    "DenyGroups"                        ? string
    "DenyUsers"                         ? string
    "HostKey"                           ? string
    "HPNDisabled"                       ? string with match (SELF, 'yes|no')
    "HPNBufferSize"                     ? long
    "IgnoreRhosts"                      ? string with match (SELF, 'yes|no')
    "IgnoreUserKnownHosts"              ? string with match (SELF, 'yes|no')
    "KerberosAuthentication"            ? string with match (SELF, 'yes|no')
    "KerberosGetAFSToken"               ? string with match (SELF, 'yes|no')
    "KerberosOrLocalPasswd"             ? string with match (SELF, 'yes|no')
    "KerberosTgtPassing"                ? string with match (SELF, 'yes|no')
    "KerberosTicketCleanup"             ? string with match (SELF, 'yes|no')
    "KeyRegenerationInterval"           ? long
    "ListenAddress"                     ? string
    "LoginGraceTime"                    ? long
    "MaxAuthTries"                      ? long
    "MaxStartups"                       ? long
    "NoneEnabled"                       ? string with match (SELF, 'yes|no')
    "PermitEmptyPasswords"              ? string with match (SELF, 'yes|no')
    "PermitRootLogin"                   ? string with match (SELF, 'yes|without-password|forced-commands-only|no')
    "PermitTunnel"                      ? string with match (SELF, 'yes|point-to-point|ethernet|no')
    "PermitUserEnvironment"             ? string with match (SELF, 'yes|no')
    "PidFile"                           ? string
    "Port"                              ? long
    "PrintLastLog"                      ? string with match (SELF, 'yes|no')
    "PrintMotd"                         ? string with match (SELF, 'yes|no')
    "RhostsAuthentication"              ? string with match (SELF, 'yes|no')
    "ServerKeyBits"                     ? long
    "ShowPatchLevel"                    ? string with match (SELF, 'yes|no')
    "StrictModes"                       ? string with match (SELF, 'yes|no')
    "Subsystem"                         ? string
    "SyslogFacility"                    ? string with match (SELF, 'AUTH|AUTHPRIV|DAEMON|USER|KERN|UUCP|NEWS|MAIL|SYSLOG|LPR|FTP|CRON|LOCAL0|LOCAL1|LOCAL2|LOCAL3|LOCAL4|LOCAL5|LOCAL6|LOCAL7')
    "TcpRcvBuf"                         ? long
    "TcpRcvBufPoll"                     ? string with match (SELF, 'yes|no')
    "UseDNS"                            ? string with match (SELF, 'yes|no')
    "UseLogin"                          ? string with match (SELF, 'yes|no')
    "UsePAM"                            ? string with match (SELF, 'yes|no')
    "UsePrivilegeSeparation"            ? string with match (SELF, 'yes|no')
    "VerifyReverseMapping"              ? string with match (SELF, 'yes|no')
    "X11DisplayOffset"                  ? long
    "X11Forwarding"                     ? string with match (SELF, 'yes|no')
    "X11UseLocalhost"                   ? string with match (SELF, 'yes|no')
};

type ssh_client_options_type = {
    include ssh_core_options_type
    "EnableSSHKeysign"                  ? string with match (SELF, 'yes|no')
    "ForwardAgent"                      ? string with match (SELF, 'yes|no')
    "ForwardX11"                        ? string with match (SELF, 'yes|no')
    "Port"                              ? long
    "RhostsAuthentication"              ? string with match (SELF, 'yes|no')
    "StrictHostKeyChecking"             ? string with match (SELF, 'yes|no')
    "UsePrivilegedPort"                 ? string with match (SELF, 'yes|no')
};

type ssh_daemon_type = {
    "options" ? ssh_daemon_options_type
    "comment_options" ? ssh_daemon_options_type
};

type ssh_client_type = {
    "options" ? ssh_client_options_type
    "comment_options" ? ssh_client_options_type
};

type component_ssh_type = {
    include structure_component
    "daemon" ? ssh_daemon_type
    "client" ? ssh_client_type
};

bind "/software/components/ssh" = component_ssh_type;
