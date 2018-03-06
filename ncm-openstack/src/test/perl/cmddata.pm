# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

=pod

=head1 cmddata module

This module provides raw command data (output and exit code) and file content.

=cut
package cmddata;

use strict;
use warnings;

# bunch of commands and their output
our %cmds;
our %files;

$cmds{keystone_db_version_missing}{cmd} = "/usr/bin/keystone-manage db_version";
$cmds{keystone_db_version_missing}{ec} = 1;

$cmds{keystone_db_version}{cmd} = "/usr/bin/keystone-manage db_version";
$cmds{keystone_db_version}{out} = 123;

$cmds{glance_db_version_missing}{cmd} = "/usr/bin/glance-manage db_version";
$cmds{glance_db_version_missing}{ec} = 1;

$cmds{glance_db_version}{cmd} = "/usr/bin/glance-manage db_version";
$cmds{glance_db_version}{out} = "ocata01";

$cmds{nova_db_version_missing}{cmd} = "/usr/bin/nova-manage db version";
$cmds{nova_db_version_missing}{ec} = 1;

$cmds{nova_db_version}{cmd} = "/usr/bin/nova-manage db version";
$cmds{nova_db_version}{out} = 347;

$cmds{neutron_db_version_missing}{cmd} = "/usr/bin/neutron-db-manage current";
$cmds{neutron_db_version_missing}{ec} = 1;

$cmds{neutron_db_version}{cmd} = "/usr/bin/neutron-db-manage current";
$cmds{neutron_db_version}{out} = "OK";

$cmds{rabbitmq_db_version_missing}{cmd} = "/usr/sbin/rabbitmqctl list_user_permissions openstack";
$cmds{rabbitmq_db_version_missing}{ec} = 1;

$cmds{rabbitmq_db_version}{cmd} = "/usr/sbin/rabbitmqctl list_user_permissions openstack";
$cmds{rabbitmq_db_version}{ec} = "/ .* .* .*";

$cmds{virsh_set_secret}{cmd} = "/usr/bin/virsh secret-define --file /var/lib/nova/tmp/secret_ceph.xml";
$cmds{virsh_set_secret}{out} = "Secret 5b67401f-dc5e-496a-8456-9a5dc40e7d3c created";

$cmds{virsh_set_key}{cmd} = "/usr/bin/virsh secret-set-value --secret 5b67401f-dc5e-496a-8456-9a5dc40e7d3c --base64 $(cat /etc/ceph/ceph.client.compute.keyring)";
$cmds{virsh_set_key}{out} = "";

1;
