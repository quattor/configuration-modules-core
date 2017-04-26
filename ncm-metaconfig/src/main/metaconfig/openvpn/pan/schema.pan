# ${license-info}
# ${developer-info}
# ${author-info}

declaration template metaconfig/openvpn/schema;

include 'quattor/schema';

@documentation{
All options shared between client and server.
}
type config_openvpn_all = {
    @{Certificate authority (CA) file in .pem format.}
    "ca" : absolute_file_path
    @{Change directory to dir prior to reading any files such as configuration files.}
    "cd" ? string
    @{Local peer's signed certificate in .pem format.}
    "cert" : absolute_file_path
    @{Encrypt data channel packets with cipher algorithm alg.}
    "cipher" : string = 'AES-256-CBC'
    @{Enable a compression algorithm.}
    "compress" ? string with match (SELF, '^(lzo|lz4)$')
    @{Use LZO compression, deprecated since 2.4.}
    "comp-lzo" ? boolean = false
    @{this option will disable OpenVPN's adaptive compression algorithm.}
    "comp-noadapt" ? boolean = false
    @{Become a daemon after all initialization functions are completed.}
    "daemon" : boolean = false
    @{TUN/TAP virtual network device.}
    "dev" : string with match (SELF, '^(tun|tap)$')
    @{this option changes the group ID of the OpenVPN process to group after initialization.}
    "group" : string = "nobody"
    @{Set TUN/TAP adapter parameters.}
    "ifconfig" ? string
    @{Local peer's private key in .pem format.}
    "key" : absolute_file_path
    @{Do not bind to local address and port.}
    "nobind" : boolean = false
    @{Don't re-read key files across SIGUSR1 or --ping-restart.}
    "persist-key" ? boolean = false
    @{Don't close and reopen TUN/TAP device or run up/down scripts across SIGUSR1 or --ping-restart.}
    "persist-tun" ? boolean = false
    @{TCP/UDP port number or port name for both local and remote.}
    "port" : type_port = 1194
    @{Use protocol p for communicating with remote host.}
    "proto" : string with match (SELF, '^(udp|tcp|tcp-client|tcp-server)$')
    @{Add an additional layer of HMAC authentication on top of the TLS control channel.}
    "tls-auth" ? string
    @{Take the TUN device MTU to be n and derive the link MTU from it.}
    "tun-mtu" : long = 1500
    @{Change the user ID of the OpenVPN process to user after initialization.}
    "user" : string = "nobody"
    @{Set output verbosity}
    "verb" ? long(0..11)
};

@documentation{
All options only available to a server.
}
type config_openvpn_server = {
    include config_openvpn_all
    @{Require, as a condition of authentication, that a connecting client has a client-config-dir file.}
    "ccd-exclusive" ? boolean
    @{Specify a directory dir for custom client config files.}
    "client-config-dir" ? string
    @{Run command cmd on client connection.}
    "client-connect" ? string
    @{Run command cmd on client disconnection.}
    "client-disconnect" ? string
    @{Tells OpenVPN to internally route client-to-client traffic.}
    "client-to-client" ? boolean = false
    @{Check peer certificate against the file crl in PEM format.}
    "crl-verify" ? string
    @{File containing Diffie Hellman parameters in .pem format.}
    "dh" ? absolute_file_path
    @{Allow multiple clients with the same common name to concurrently connect.}
    "duplicate-cn" ? boolean = false
    @{Set aside a pool of subnets to be dynamically allocated to connecting clients.}
    "ifconfig-pool" ? string
    @{Modifies the --ifconfig-pool directive to allocate individual TUN interface addresses for clients.}
    "ifconfig-pool-linear" ? boolean = false
    @{Persist/unpersist ifconfig-pool data to file.}
    "ifconfig-pool-persist" ? string
    @{define keepalive interval and timeout.}
    "keepalive" : long[2] = list(10, 120)
    @{Local host name or IP address for bind.}
    "local" ? string
    @{Append logging messages to file.}
    "log-append" ? absolute_file_path
    @{Enable a TCP server on IP:port to handle daemon management functions.}
    "management" ? string
    @{Limit server to a maximum of n concurrent clients.}
    "max-clients" ? long
    @{Set the TOS field of the tunnel packet to what the payload's TOS is.}
    "passtos" ? boolean = false
    @{Push a config file option back to the client for remote execution.}
    "push" ? string[]
    @{This directive offers policy-level control over OpenVPN's usage of external programs and scripts.}
    "script-security" ? long(0..3)
    @{A helper directive designed to simplify the configuration of OpenVPN's server mode.}
    "server" ? string
    @{A helper directive to simplify the config of OpenVPN's server in eth bridging configurations.}
    "server-bridge" ? string
    @{Maximum number of output packets queued before TCP.}
    "tcp-queue-limit" ? long
    @{Enable TLS and assume server role during TLS handshake.}
    "tls-server" ? boolean = false
    @{Run command cmd to verify the X509 name of a pending TLS connection.}
    "tls-verify" ? string
    @{Configure virtual addressing topology when running in --dev tun mode.}
    "topology" ? string with match (SELF, '^(net30|p2p|subnet)')
    @{Run command cmd after successful TUN/TAP device open.}
    "up" ? string
};

@documentation{
All options only available to a client.
}
type config_openvpn_client = {
    include config_openvpn_all
    @{A helper directive designed to simplify the configuration of OpenVPN's client mode.}
    "client" : boolean = false
    @{Maximum rumber of routes.}
    "max-routes" ? long(0..)
    @{Require that peer certificate was signed with an explicit key usage and extended key usage.}
    "remote-cert-tls" ? string with match (SELF, '^(client|server)')
    @{Remote host name or IP address.}
    "remote" : string[]
    @{When multiple --remote address are specified, initially randomize the order of the list.}
    "remote-random" ? boolean = false
    @{If hostname resolve fails for --remote, retry resolve before failing.}
    "resolv-retry" ? string
    @{Enable TLS and assume client role during TLS handshake.}
    "tls-client" : boolean = false
    @{Exit on TLS negotiation failure.}
    "tls-exit" ? boolean = false
};
