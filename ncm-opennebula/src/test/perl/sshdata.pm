# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}
=pod
=head1 sshdata module
This module provides raw ssh data (output and exit code)
=cut
package sshdata;

use strict;
use warnings;

our %ssh;
my $cephsecfile = "/var/lib/one/templates/secret/secret_ceph.xml";
my $libvirtkfile = "/etc/ceph/ceph.client.libvirt.keyring";
my $uuid = "8371ae8a-386d-44d7-a228-c42de4259c6e";
my $secret = "AQCGZr1TeFUBMRBBHExosSnNXvlhuKexxcczpw==";

$ssh{ssh_create_libvirt_secret}{command} = "su - oneadmin -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r hyp104 sudo /usr/bin/virsh secret-define --file $cephsecfile";
$ssh{ssh_create_libvirt_secret}{out} = <<'EOF';
Secret 8371ae8a-386d-44d7-a228-c42de4259c6e created

EOF
$ssh{ssh_create_libvirt_secret}{exit} = 0;

$ssh{ssh_list_libvirt_keyfile}{command} = "su - oneadmin -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r hyp104 /usr/bin/cat $libvirtkfile";
$ssh{ssh_list_libvirt_keyfile}{out} = <<'EOF';
key=AQCGZr1TeFUBMRBBHExosSnNXvlhuKexxcczpw==

EOF
$ssh{ssh_list_libvirt_keyfile}{exit} = 0;

$ssh{ssh_list_libvirt_set_secret}{command} = "su - oneadmin -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r hyp104 sudo /usr/bin/virsh secret-set-value --secret $uuid --base64 $secret";
$ssh{ssh_list_libvirt_set_secret}{out} = <<'EOF';
Secret value set

EOF
$ssh{ssh_list_libvirt_set_secret}{exit} = 0;


$ssh{ssh_libvirtd_service_restart}{command} = "su - oneadmin -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r hyp104 sudo /usr/sbin/service libvirtd restart";
$ssh{ssh_libvirtd_service_restart}{out} = <<'EOF';
EOF
$ssh{ssh_libvirtd_service_restart}{exit} = 0;

$ssh{ssh_libviguests_service_restart}{command} = "su - oneadmin -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r hyp104 sudo /usr/sbin/service libvirt-guests restart";
$ssh{ssh_libviguests_service_restart}{out} = <<'EOF';
EOF
$ssh{ssh_libviguests_service_restart}{exit} = 0;

$ssh{opennebula_service_restart}{command} = "/usr/sbin/service opennebula restart";
$ssh{opennebula_service_restart}{out} = <<'EOF';
EOF
$ssh{opennebula_service_restart}{exit} = 0;

$ssh{ssh_run_uname}{command} = "su - oneadmin -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r hyp104 uname";
$ssh{ssh_run_uname}{out} = <<'EOF';
hyp104
EOF
$ssh{ssh_run_uname}{exit} = 0;

$ssh{ssh_check_keys}{command} = "su - oneadmin -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r -o StrictHostKeyChecking=no hyp104 uname";
$ssh{ssh_check_keys}{out} = <<'EOF';
hyp104
EOF
$ssh{ssh_check_keys}{exit} = 0;

1;
