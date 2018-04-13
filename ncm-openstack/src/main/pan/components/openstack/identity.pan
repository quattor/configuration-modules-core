# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/identity;

include 'components/openstack/identity/keystone';

type openstack_valid_domain = string with openstack_is_valid_identity(SELF, 'domain');

type openstack_valid_project = string with openstack_is_valid_identity(SELF, 'project');

type openstack_valid_user = string with openstack_is_valid_identity(SELF, 'user');

@{openstack identity v3 region}
type openstack_identity_region = {
    'description' ? string
    'parent_region_id' ? openstack_valid_region
};

@{openstack identity v3 domain}
type openstack_identity_domain = {
    'description' ? string
};

@{openstack identity v3 project.
  The is_domain boolean is not supported (no update/delete equivalent).}
type openstack_identity_project = {
    'description' ? string
    'domain_id' ? openstack_valid_domain
    'parent_id' ? openstack_valid_project
};

@{openstack identity v3 user.
  One can add as many "extra" items as one wishes, e.g. description}
type openstack_identity_user = {
    'domain_id' ? openstack_valid_domain
    'default_project_id' ? openstack_valid_project
    'password' ? string
    @{description is part of the "extra" attributes}
    'description' ? string
};

@{openstack identity v3 group}
type openstack_identity_group = {
    'domain_id' ? openstack_valid_domain
    'description' ? string
};

@{openstack identity v3 servicce}
type openstack_identity_service = {
    'description' ? string
    'type' : choice('compute', 'ec2', 'identity', 'image', 'network', 'volume')
};

#TODO There is no role support yet (as there is no description attribute).
@documentation {
Type to define OpenStack identity v3 services.
}
type openstack_identity_config = {
    'keystone' ? openstack_keystone_config
    @{region, key is used as region id}
    'region' ? openstack_identity_region{}
    @{domain, key is used as domain name}
    'domain' ? openstack_identity_domain{}
    @{project, key is used as project name}
    'project' ? openstack_identity_project{}
    @{user, key is used as user name}
    'user' ? openstack_identity_user{}
    @{group, key is used as group name}
    'group' ? openstack_identity_group{}
    @{service, key is used as service name}
    'service' ? openstack_identity_service{}
} with openstack_oneof(SELF, 'keystone');
