# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

@author{
        name  = Guillaume PHILIPPON
        email = guillaume.philippon@lal.in2p3.fr
}

declaration template components/ganglia/schema;

include 'quattor/schema';

type daemon_ganglia = {
    'config_file' : string = '/etc/ganglia/gmetad.conf'
    'data_source' : string{}
    'gridname' : string = 'unspecified'
    'case_sensitive_hostnames' : long = 1
};

type metric_collection_groups_client_ganglia = {
    'name' : string
    'title' ? string
    'value_threshold' ? string
};

type collection_groups_client_ganglia = {
    'collect_once' ? boolean
    'time_threshold' ? long
    'metric' : metric_collection_groups_client_ganglia[]
    'collect_every' ? long
};

type modules_client_ganglia = {
    'name' : string
    'path' ? string
    'enabled' ? boolean
    'params' ? string
    'param' ? string{}
};

type access_acl_client_ganglia = {
    'ip' : string
    'mask' : string
    'action' : string
};

type acl_client_ganglia = {
    'default' : string
    'access' ? access_acl_client_ganglia[]
};

type udp_accept_channel_client_ganglia = {
    'port' : long = 8649
    'bind' ? string
    'interface' ? string
    'family' ? string
    'timeout' ? long
    'acl' ? acl_client_ganglia
};

type udp_recv_channel_client_ganglia = {
    'port' : long = 8649
    'mcast_join' ? string
    'mcast_if' ? string
    'bind' ? string
    'family' ? string
    'acl' ? acl_client_ganglia
};

type udp_send_channel_client_ganglia = {
    'host' : string
    'port' : long = 8649
    'ttl' : long = 1
    'mcast_join' ? string
    'mcast_if' ? string
};

type host_client_ganglia =  {
    'location' : string = 'unspecified'
};

type cluster_client_ganglia = {
    'name' : string
    'owner' : string = 'unspecified'
    'latlong' : string = 'unspecified'
    'url' : string = 'unspecified'
};

type globals_client_ganglia = {
    'daemonize' : boolean = true
    'setuid' : boolean = true
    'user' : string = 'nobody'
    'debug_level' : long = 0
    'max_udp_msg_len' : long = 1472
    'mute' : boolean = false
    'deaf' : boolean = false
    'allow_extra_data' ? boolean
    'host_dmax' : long = 1209600
    'cleanup_threshold' : long = 300
    'send_metadata_interval' ? long
    'gexec' : boolean = false
    'module_dir' ? string
};

type client_ganglia = {
    'config_file' : string = '/etc/ganglia/gmond.conf'
    'globals' : globals_client_ganglia = dict()
    'cluster' : cluster_client_ganglia = dict()
    'host' : host_client_ganglia = dict()
    'udp_send_channel' : udp_send_channel_client_ganglia = dict()
    'udp_recv_channel' : udp_recv_channel_client_ganglia = dict()
    'tcp_accept_channel' : udp_accept_channel_client_ganglia = dict()
    'modules' ? modules_client_ganglia[]
    'includes' ? string[]
    'collection_groups' : collection_groups_client_ganglia[] = list()
};

type component_ganglia = {
    include structure_component
    'package' : string
    'daemon' ? daemon_ganglia
    'client' ? client_ganglia
};

bind '/software/components/ganglia' = component_ganglia;
