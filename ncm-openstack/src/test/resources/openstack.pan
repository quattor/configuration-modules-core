object template openstack;

"/software/components/openstack/compute/nova/quattor/service/public/host" = "somehost";

include 'os_resources';

# generate the identity data from other OS services
include 'components/openstack/identity/gather';

"/software/components/openstack/identity/client" = openstack_identity_gather(SELF);
