# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/container-infra;

include 'components/openstack/container-infra/magnum';

@documentation{
    Type to define OpenStack container orchestration engine
}
type openstack_container_infra_config = {
    'magnum' ? openstack_magnum_config
} with openstack_oneof(SELF, 'magnum');
