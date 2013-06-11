# This should be included from quattor/schema

declaration template components/network/core-schema;

############################################################
#
# type definition structure_route
#
############################################################

type structure_route = {
  "address" ? type_ip
  "netmask" ? type_ip
  "gateway" ? type_ip
};

###########################################################
#
# type definition structure_interface_alias
#
############################################################

type structure_interface_alias = {
  "ip"      ? type_ip
  "netmask" : type_ip
  "broadcast" ? type_ip
};

# Describes the bonding options for configuring channel bonding on SL5
# and similar.
type structure_bonding_options = {
    "mode" : long
    "miimon" : long
    "updelay" : long
    "primary" : string with exists("/system/network/interfaces/" + SELF)
};

#
# structure_interface_offload
#

type structure_ethtool_offload = {
    "rx"            ? string with match (SELF, '^on|off$')
    "tx"            ? string with match (SELF, '^on|off$')
    "tso"           ? string with match (SELF, '^on|off$')
    "gro"           ? string with match (SELF, '^on|off$')
};

type structure_ethtool_ring = {
    "rx"            ? long
    "tx"            ? long
    "rx-mini"       ? long
    "rx-jumbo"      ? long
};

type structure_ethtool = {
# ethtool -s arguments
#        wol p|u|m|b|a|g|s|d...
#              Sets Wake-on-LAN options.  Not all devices support this.  The argument to this option is  a  string
#              of characters specifying which options to enable.
#              p  Wake on phy activity
#              u  Wake on unicast messages
#              m  Wake on multicast messages
#              b  Wake on broadcast messages
#              a  Wake on ARP
#              g  Wake on MagicPacket(tm)
#              s  Enable SecureOn(tm) password for MagicPacket(tm)
#              d  Disable (wake on nothing).  This option clears all previous option
    "wol"       ? string with match (SELF, '^p|u|m|b|a|g|s|d$')
    "autoneg"   ? string with match (SELF, '^on|off$')
    "duplex"    ? string with match (SELF, '^half|full$')
    "speed"     ? long
};

############################################################
#
# type definition structure_interface
#
############################################################

type structure_interface = {
  "ip"      ? type_ip
  "gateway" ? type_ip
  "netmask" ? type_ip
  "broadcast" ? type_ip
  "driver"  ? string
  "bootproto" ? string
  "onboot" ? string
  "type"    ? string
  "device"  ? string
  "master" ? string
  "mtu"       ? long
  "route"   ? structure_route[]
  "aliases" ? structure_interface_alias{}
  "set_hwaddr" ? boolean
  "bridge"    ? string with exists ("/system/network/interfaces/" + SELF)
  "bonding_opts" ? structure_bonding_options
  "offload"   ? structure_ethtool_offload
  "ring"      ? structure_ethtool_ring
  "ethtool"   ? structure_ethtool

  "vlan" ? boolean
  "physdev"    ? string with exists ("/system/network/interfaces/" + SELF)
  "nmcontrolled"     ? boolean
};


############################################################
#
# type definition structure_network
#
############################################################
type structure_network = {
     "domainname"       : type_fqdn
     "hostname"         : type_shorthostname
     "realhostname"     ? type_fqdn
     "default_gateway"  ? type_ip
     "gatewaydev"       ? string with exists ("/system/network/interfaces/" + SELF)
     "interfaces"       : structure_interface{}
     "nameserver"       : type_ip[]
     "nisdomain"        ? type_fqdn
     "nozeroconf"       ? boolean
     "set_hwaddr"       ? boolean
     "nmcontrolled"     ? boolean
     "allow_nm"         ? boolean
};

