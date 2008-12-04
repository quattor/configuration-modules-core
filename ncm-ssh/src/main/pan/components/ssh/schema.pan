# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ssh/schema;

include quattor/schema;

type ssh_daemon_options_type = {
    "AFSTokenPassing"                   ? string with match (self, 'yes|no')
    "AcceptEnv"                         ? string with match (self, 'yes|no')
    "AddressFamily"                     ? string with match (self, 'any|inet|inet6')
    "AllowGroups"                       ? string
    "AllowTcpForwarding"                ? string with match (self, 'yes|no')
    "AllowUsers"                        ? string
    "AuthorizedKeysFile"                ? string
    "Banner"                            ? string
    "ChallengeResponseAuthentication"   ? string with match (self, 'yes|no')
    "Ciphers"                           ? string
    "ClientAliveCountMax"               ? long
    "ClientAliveInterval"               ? long
    "Compression"                       ? string with match (self, 'yes|delayed|no')
    "DenyGroups"                        ? string
    "DenyUsers"                         ? string
    "GSSAPIAuthentication"              ? string with match (self, 'yes|no')
    "GSSAPICleanupCredentials"          ? string with match (self, 'yes|no')
    "GatewayPorts"                      ? string with match (self, 'yes|no')
    "HostKey"                           ? string
    "HostbasedAuthentication"           ? string with match (self, 'yes|no')
    "HPNDisabled"                       ? string with match (self, 'yes|no')
    "HPNBufferSize"                     ? long
    "IgnoreRhosts"                      ? string with match (self, 'yes|no')
    "IgnoreUserKnownHosts"              ? string with match (self, 'yes|no')
    "KerberosAuthentication"            ? string with match (self, 'yes|no')
    "KerberosGetAFSToken"               ? string with match (self, 'yes|no')
    "KerberosOrLocalPasswd"             ? string with match (self, 'yes|no')
    "KerberosTgtPassing"                ? string with match (self, 'yes|no')
    "KerberosTicketCleanup"             ? string with match (self, 'yes|no')
    "KeyRegenerationInterval"           ? long
    "ListenAddress"                     ? string
    "LogLevel"                          ? string with match (self, 'DEBUG|INFO|NOTICE|WARNING|ERR|CRIT|ALERT|EMERG')
    "LoginGraceTime"                    ? long
    "MACs"                              ? string
    "MaxAuthTries"                      ? long
    "MaxStartups"                       ? long
    "NoneEnabled"                       ? string with match (self, 'yes|no')
    "PasswordAuthentication"            ? string with match (self, 'yes|no')
    "PermitEmptyPasswords"              ? string with match (self, 'yes|no')
    "PermitRootLogin"                   ? string with match (self, 'yes|without-password|forced-commands-only|no')
    "PermitTunnel"                      ? string with match (self, 'yes|point-to-point|ethernet|no')
    "PermitUserEnvironment"             ? string with match (self, 'yes|no')
    "PidFile"                           ? string
    "Port"                              ? long
    "PrintLastLog"                      ? string with match (self, 'yes|no')
    "PrintMotd"                         ? string with match (self, 'yes|no')
    "Protocol"                          ? string
    "PubkeyAuthentication"              ? string with match (self, 'yes|no')
    "RSAAuthentication"                 ? string with match (self, 'yes|no')
    "RhostsAuthentication"              ? string with match (self, 'yes|no')
    "RhostsRSAAuthentication"           ? string with match (self, 'yes|no')
    "SendEnv"                           ? string with match (self, 'yes|no')
    "ServerKeyBits"                     ? long
    "ShowPatchLevel"                    ? string with match (self, 'yes|no')
    "StrictModes"                       ? string with match (self, 'yes|no')
    "Subsystem"                         ? string
    "SyslogFacility"                    ? string with match (self, 'AUTH|AUTHPRIV|DAEMON|USER|KERN|UUCP|NEWS|MAIL|SYSLOG|LPR|FTP|CRON|LOCAL0|LOCAL1|LOCAL2|LOCAL3|LOCAL4|LOCAL5|LOCAL6|LOCAL7')
    "TCPKeepAlive"                      ? string with match (self, 'yes|no')
    "TcpRcvBuf"                         ? long
    "TcpRcvBufPoll"                     ? string with match (self, 'yes|no')
    "UseDNS"                            ? string with match (self, 'yes|no')
    "UseLogin"                          ? string with match (self, 'yes|no')
    "UsePAM"                            ? string with match (self, 'yes|no')
    "UsePrivilegeSeparation"            ? string with match (self, 'yes|no')
    "VerifyReverseMapping"              ? string with match (self, 'yes|no')
    "X11DisplayOffset"                  ? long
    "X11Forwarding"                     ? string with match (self, 'yes|no')
    "X11UseLocalhost"                   ? string with match (self, 'yes|no')
    "XAuthLocation"                     ? string
};

type ssh_client_options_type = {
    "EnableSSHKeysign"                  ? string with match (self, 'yes|no')
    "ForwardAgent"                      ? string with match (self, 'yes|no')
    "ForwardX11"                        ? string with match (self, 'yes|no')
    "HostbasedAuthentication"           ? string with match (self, 'yes|no')
    "Port"                              ? long
    "Protocol"                          ? string with match (self, '1|2|1,2|2,1')
    "RhostsAuthentication"              ? string with match (self, 'yes|no')
    "StrictHostKeyChecking"             ? string with match (self, 'yes|no')
    "UsePrivilegedPort"                 ? string with match (self, 'yes|no')
};

type ssh_daemon_type = {
    "options" ? ssh_daemon_options_type
    "comment_options" ? ssh_daemon_options_type
};

type ssh_client_type = {
    "options" ? ssh_client_options_type
};

type component_ssh_type = {
    include structure_component
    "daemon" ? ssh_daemon_type
    "client" ? ssh_client_type
};

type "/software/components/ssh" = component_ssh_type;
