object template configure;

function pkg_repl = { null; };
include 'components/gmond/config';
'/software/components/gmond/dependencies' = null;

prefix '/software/components/gmond';
'file' = '/etc/ganglia/gmond.conf';
'collection_group/0/metric/0/name' = 'test';
'globals/daemonize' = true;
'globals/allow_extra_data' = false;
'udp_send_channel/0/port' = 123;
'udp_send_channel/0/bind_hostname' = true;
'udp_recv_channel/0/port' = 456;
'tcp_accept_channel/0/port' = 789;
