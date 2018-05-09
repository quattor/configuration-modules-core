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

$cmds{nova_set_secret}{cmd} = "/usr/bin/virsh secret-define --file /var/lib/nova/tmp/secret_ceph.xml";
$cmds{nova_set_secret}{out} = "Secret 5b67401f-dc5e-496a-8456-9a5dc40e7d3c created";

$cmds{nova_set_key}{cmd} = "/usr/bin/virsh secret-set-value --secret 5b67401f-dc5e-496a-8456-9a5dc40e7d3c --base64 $(cat /etc/ceph/ceph.client.compute.keyring)";
$cmds{nova_set_key}{out} = "";

$cmds{cinder_set_secret}{cmd} = "/usr/bin/virsh secret-define --file /var/lib/cinder/tmp/secret_ceph.xml";
$cmds{cinder_set_secret}{out} = "Secret afe09a7e-3d8e-11e8-ac85-63e6230f8c43 created";

$cmds{cinder_set_key}{cmd} = "/usr/bin/virsh secret-set-value --secret afe09a7e-3d8e-11e8-ac85-63e6230f8c43 --base64 $(cat /etc/ceph/ceph.client.volumes.keyring)";
$cmds{cinder_set_key}{out} = "";

$files{invalidcephkey}{path} = "/etc/ceph/somekey";
$files{invalidcephkey}{txt} = "abc";

$files{novacephkey}{path} = "/etc/ceph/ceph.client.compute.keyring";
$files{novacephkey}{txt} = "key=abc";

$files{cindercephkey}{path} = "/etc/ceph/ceph.client.volumes.keyring";
$files{cindercephkey}{txt} = "key=defgh";

$cmds{cinder_db_version}{cmd} = "/usr/bin/cinder-manage db version";
$cmds{cinder_db_version}{out} = 1;

$cmds{cinder_db_version_missing}{cmd} = "/usr/bin/cinder-manage db version";
$cmds{cinder_db_version_missing}{ec} = 1;

$cmds{manila_db_version}{cmd} = "/usr/bin/manila-manage db version";
$cmds{manila_db_version}{out} = 1;

$cmds{manila_db_version_missing}{cmd} = "/usr/bin/manila-manage db version";
$cmds{manila_db_version_missing}{ec} = 1;


1;
