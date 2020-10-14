declaration template metaconfig/conntrackd/schema;

include 'pan/types';

@documentation{
    Conntrackd config
}

@documentation{
    There are 3 main synchronization modes or protocols: NOTRACK, ALARM and FTFW.
}
type conntrackd_service_sync_mode = {
    'type' : choice('FTFW', 'ALARM', 'NOTRACK,') = 'FTFW'
    'DisableExternalCache' ? boolean
    'CommitTimeout' ? long(0..)
    'PurgeTimeout' ? long(0..)
};

@documentation{
    There are 3 transport protocols: TCP, Multicast and UDP.
}
type conntrackd_service_sync_transport = {
    'type' : choice('TCP', 'Multicast', 'UDP')
    'IPv4_address' ? type_ipv4
    'IPv6_address' ? type_ipv6
    'IPv4_Destination_Address' ? type_ipv4
    'IPv6_Destionation_Address' ? type_ipv6
    'Port' ? type_port
    'Interface'? string with path_exists(format('/system/network/interfaces/%s', SELF))
    'IPv4_interface' ? type_ipv4
    'SndSocketBuffer' ? long(0..)
    'RcvSocketBuffer' ? long(0..)
    'Checksum' ? boolean
};

@documentation{
    This top-level section defines how conntrackd should handle synchronization with other cluster nodes.
}
type conntrackd_service_sync = {
    'mode' : conntrackd_service_sync_mode
    'transport' : conntrackd_service_sync_transport[]
};

@documentation{
    Unix socket configuration.
    This socket is used by conntrackd to listen to external commands like `conntrackd -k' or `conntrackd -n'.
}
type conntrackd_service_general_unix = {
    'Path' : string = '/var/run/conntrackd.ctl'
    'Backlog' : long = 20
};

type conntrackd_service_general_filter_action = {
    'action' : choice('Accept', 'Ignore')
};
type conntrackd_service_general_filter_protocol_option = choice('TCP', 'SCTP', 'DCCP', 'UDP', 'ICMP', 'IPv6-ICMP');

type conntrackd_service_general_filter_state_option = choice(
    'SYN_SENT', 'SYN_RECV', 'ESTABLISHED', 'FIN_WAIT', 'CLOSE_WAIT', 'LAST_ACK', 'TIME_WAIT', 'CLOSED', 'LISTEN');

type conntrackd_service_general_filter_state = {
    include conntrackd_service_general_filter_action
    'states' : conntrackd_service_general_filter_state_option[]
};

type conntrackd_service_general_filter_protocol = {
    include conntrackd_service_general_filter_action
    'protocols' : conntrackd_service_general_filter_protocol_option[]
};

type conntrackd_service_general_filter_address = {
    include conntrackd_service_general_filter_action
    'IPv4_address' ? type_ipv4[]
    'IPv6_address' ? type_ipv6[]
};

@documentation{
    Event filtering. This clause allows you to filter certain traffic.
    There are currently three filter-sets: Protocol, Address and State.
    The filter is attached to an action that can be: Accept or Ignore.
    Thus, you can define the event filtering policy of the filter-sets in positive or negative
    logic depending on your needs.
    You can select if conntrackd filters the event messages from user-space or kernel-space.
    The kernel-space event filtering saves some CPU cycles by avoiding the copy of the event
    message from kernel-space to user-space.
    The kernel-space event filtering is prefered, however,
    you require a Linux kernel >= 2.6.29 to filter from kernel-space.
}

type conntrackd_service_general_filter = {
    'from' : choice('Kernelspace', 'Userspace') = 'Userspace'
    'protocol' ?  conntrackd_service_general_filter_protocol
    'address' ? conntrackd_service_general_filter_address
    'state' ? conntrackd_service_general_filter_state
};

@documentation{
    This top-level section contains generic configuration directives for the conntrackd daemon
}
type conntrackd_service_general = {
    'Nice' : long(-20..19) = -20
    'HashSize' ? long(1..)
    'HashLimit' ? long(1..)
    'Logfile' ? string # <on|off|filename>
    'Syslog' ? string  # <on|off|facility>
    'LockFile' : string = '/var/lock/conntrack.lock'
    'UNIX' : conntrackd_service_general_unix = dict()
    'NetlinkBufferSize' ? long(102400..)
    'NetlinkBufferSizeMaxGrowth' ? long(204800..)
    'filter' ? conntrackd_service_general_filter
};

type conntrackd_service = {
    'sync' ? conntrackd_service_sync
    'general' : conntrackd_service_general
};
