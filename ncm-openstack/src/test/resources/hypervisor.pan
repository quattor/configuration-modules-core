object template hypervisor;

include 'common_resources';

variable MY_IP = '10.0.1.3';

# Hardware section

prefix "/system/network";
"hostname" = "hypervisor";

# Enable hypervisor

"/software/components/openstack/hypervisor" = dict();

# Nova/Compute section

prefix "/software/components/openstack/compute/nova";
"vnc" = dict(
    "enabled", true,
    "vncserver_listen", "0.0.0.0",
    "novncproxy_base_url", format('http://%s:6080/vnc_auto.html', OPENSTACK_HOST_SERVER),
);
# Libvirt conf using Ceph backend
"libvirt" = dict(
    "virt_type", "kvm",
    "images_rbd_pool", "compute",
    "images_type", "rbd",
    "rbd_secret_uuid", "5b67401f-dc5e-496a-8456-9a5dc40e7d3c",
    "rbd_user", "compute",
);
