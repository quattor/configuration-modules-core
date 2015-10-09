# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ssh/schema;

include 'quattor/types/component';
include 'pan/types';

type ssh_yesnostring = string with match(SELF, "^(yes|no)$");

type ssh_preferred_authentication = string with match(SELF, '^(gssapi-with-mic|hostbased|publickey|keyboard-interactive|password)$');

type ssh_core_options_type = {
    "AddressFamily"                     ? string with match (SELF, '^(any|inet6?)$')
    "ChallengeResponseAuthentication"   ? ssh_yesnostring
    "Ciphers"                           ? string
    "Compression"                       ? string with match (SELF, '^(yes|delayed|no)$')
    "GSSAPIAuthentication"              ? ssh_yesnostring
    "GSSAPICleanupCredentials"          ? ssh_yesnostring
    "GSSAPIKeyExchange"                 ? ssh_yesnostring
    "GatewayPorts"                      ? ssh_yesnostring
    "HostbasedAuthentication"           ? ssh_yesnostring
    "LogLevel"                          ? string with match (SELF, '^(QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG[123]?)$')
    "MACs"                              ? string
    "PasswordAuthentication"            ? ssh_yesnostring
    "Protocol"                          ? string
    "PubkeyAuthentication"              ? ssh_yesnostring
    "RSAAuthentication"                 ? ssh_yesnostring
    "RhostsRSAAuthentication"           ? ssh_yesnostring
    "SendEnv"                           ? ssh_yesnostring
    "TCPKeepAlive"                      ? ssh_yesnostring
    "XAuthLocation"                     ? string
};

type ssh_daemon_options_type = {
    include ssh_core_options_type
    "AFSTokenPassing"                   ? ssh_yesnostring
    @{AcceptEnv, one per line}
    "AcceptEnv"                         ? string[]
    "AllowAgentForwarding"              ? ssh_yesnostring
    "AllowGroups"                       ? string
    "AllowTcpForwarding"                ? ssh_yesnostring
    "AllowUsers"                        ? string
    "AuthorizedKeysFile"                ? string
    "AuthorizedKeysCommand"             ? string
    "AuthorizedKeysCommandRunAs"        ? string
    "Banner"                            ? string
    "ClientAliveCountMax"               ? long
    "ClientAliveInterval"               ? long
    "DenyGroups"                        ? string
    "DenyUsers"                         ? string
    "GSSAPIStrictAcceptorCheck"         ? ssh_yesnostring
    @{HostKey, one per line}
    "HostKey"                           ? string[]
    "HPNDisabled"                       ? ssh_yesnostring
    "HPNBufferSize"                     ? long
    "IgnoreRhosts"                      ? ssh_yesnostring
    "IgnoreUserKnownHosts"              ? ssh_yesnostring
    "KbdInteractiveAuthentication"      ? ssh_yesnostring
    "KerberosAuthentication"            ? ssh_yesnostring
    "KerberosGetAFSToken"               ? ssh_yesnostring
    "KerberosOrLocalPasswd"             ? ssh_yesnostring
    "KerberosTgtPassing"                ? ssh_yesnostring
    "KerberosTicketAuthentication"      ? ssh_yesnostring
    "KerberosTicketCleanup"             ? ssh_yesnostring
    "KeyRegenerationInterval"           ? long
    @{ListenAddress, one per line}
    "ListenAddress"                     ? type_hostport[]
    "LoginGraceTime"                    ? long
    "MaxAuthTries"                      ? long
    "MaxStartups"                       ? long
    "NoneEnabled"                       ? ssh_yesnostring
    "PermitEmptyPasswords"              ? ssh_yesnostring
    "PermitRootLogin"                   ? string with match (SELF, '^(yes|without-password|forced-commands-only|no)$')
    "PermitTunnel"                      ? string with match (SELF, '^(yes|point-to-point|ethernet|no)$')
    "PermitUserEnvironment"             ? ssh_yesnostring
    "PidFile"                           ? string
    "Port"                              ? long
    "PrintLastLog"                      ? ssh_yesnostring
    "PrintMotd"                         ? ssh_yesnostring
    "RhostsAuthentication"              ? ssh_yesnostring
    "ServerKeyBits"                     ? long
    "ShowPatchLevel"                    ? ssh_yesnostring
    "StrictModes"                       ? ssh_yesnostring
    "Subsystem"                         ? string
    "SyslogFacility"                    ? string with match (SELF, '^(AUTH(PRIV)?|DAEMON|USER|KERN|UUCP|NEWS|MAIL|SYSLOG|LPR|FTP|CRON|LOCAL[0-7])$')
    "TcpRcvBuf"                         ? long
    "TcpRcvBufPoll"                     ? ssh_yesnostring
    "UseDNS"                            ? ssh_yesnostring
    "UseLogin"                          ? ssh_yesnostring
    "UsePAM"                            ? ssh_yesnostring
    "UsePrivilegeSeparation"            ? ssh_yesnostring
    "VerifyReverseMapping"              ? ssh_yesnostring
    "X11DisplayOffset"                  ? long
    "X11Forwarding"                     ? ssh_yesnostring
    "X11UseLocalhost"                   ? ssh_yesnostring
};

type ssh_client_options_type = {
    include ssh_core_options_type
    "BatchMode"                         ? ssh_yesnostring
    "ConnectTimeout"                    ? long
    "EnableSSHKeysign"                  ? ssh_yesnostring
    "ForwardAgent"                      ? ssh_yesnostring
    "ForwardX11"                        ? ssh_yesnostring
    "GSSAPIDelegateCredentials"         ? ssh_yesnostring
    "Port"                              ? long
    "PreferredAuthentications"          ? ssh_preferred_authentication[]
    "RhostsAuthentication"              ? ssh_yesnostring
    "StrictHostKeyChecking"             ? ssh_yesnostring
    "UsePrivilegedPort"                 ? ssh_yesnostring
};

type ssh_daemon_type = {
    "options" ? ssh_daemon_options_type
    "comment_options" ? ssh_daemon_options_type
    "sshd_path" ? string
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
