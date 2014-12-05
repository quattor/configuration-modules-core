### DESCRIPTION

The _openvpn_ component manages the OpenVPN server and the OpenVPN client configuration.
OpenVPN is used to make virtual private networks over the internet.

### COMPONENT STRUCTURE

This component can be used to configure an OpenVPN and/or OpenVPN
client.

The server is only configured if its configuration exists under
`/software/components/openvpn/server`, the client parts are configured if
the configuration under `/software/components/openvpn/clients` is defined.
It is possible to generate multiple configurations of the client and
server type.  When setting one of the boolean options to True you'll
activate the option in the configuration.

### SEE ALSO

http://openvpn.net/index.php/documentation/manuals/openvpn-20x-manpage.html
