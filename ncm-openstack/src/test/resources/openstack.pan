object template openstack;

include 'os_resources';

# generate the identity data from other OS services
include 'components/openstack/identity/gather';

"/software/components/openstack/identity/client" = openstack_identity_gather(SELF);
