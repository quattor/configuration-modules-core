declaration template components/network/types/network/ethtool;

@documentation{
    interface ethtool offload
}
type network_ethtool_offload = {
    "rx" ? choice('on', 'off')
    "tx" ? choice('on', 'off')
    @{Set the TCP segment offload parameter to "off" or "on"}
    "tso" ? choice('on', 'off')
    "gro" ? choice('on', 'off')
    "gso" ? choice('on', 'off')
};

@documentation{
    Set the ethernet transmit or receive buffer ring counts.
    See ethtool --show-ring for the values.
}
type network_ethtool_ring = {
    "rx" ? long
    "tx" ? long
    "rx-mini" ? long
    "rx-jumbo" ? long
};

@documentation{
    Set the number of channels.
    See ethtool --show-channels for the values.
}
type network_ethtool_channels = {
    "rx" ? long(0..)
    "tx" ? long(0..)
    "other" ? long(0..)
    "combined" ? long(0..)
};

@documentation{
    ethtool wol p|u|m|b|a|g|s|d...
    from the man page
        Sets Wake-on-LAN options.  Not all devices support this.  The argument to this option is a string
        of characters specifying which options to enable.
            p  Wake on phy activity
            u  Wake on unicast messages
            m  Wake on multicast messages
            b  Wake on broadcast messages
            a  Wake on ARP
            g  Wake on MagicPacket(tm)
            s  Enable SecureOn(tm) password for MagicPacket(tm)
            d  Disable (wake on nothing).  This option clears all previous option
}
type network_ethtool_wol = string with match (SELF, '^(p|u|m|b|a|g|s|d)+$');

@documentation{
    ethtool
}
type network_ethtool = {
    "wol" ? network_ethtool_wol
    "autoneg" ? choice('on', 'off')
    "duplex" ? choice('half', 'full')
    "speed" ? long
    "channels" ? network_ethtool_channels
};

type network_interface_ethtool = {
    "offload" ? network_ethtool_offload
    "ring" ? network_ethtool_ring
    "ethtool" ? network_ethtool
};
