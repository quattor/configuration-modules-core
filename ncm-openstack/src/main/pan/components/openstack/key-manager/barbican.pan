# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/key-manager/barbican;

include 'components/openstack/identity';


@documentation{
    Barbican default section
}
type openstack_barbican_DEFAULTS = {
    include openstack_DEFAULTS
    @{SQLAlchemy connection string for the reference implementation
    registry server. Any valid SQLAlchemy connection string is fine.
    For some weird reason Barbican does not use the [database] section}
    'sql_connection' : string
};

type openstack_quattor_barbican = openstack_quattor;

@documentation{
    list of Barbican configuration sections
}
type openstack_barbican_config = {
    'DEFAULT' : openstack_barbican_DEFAULTS
    'keystone_authtoken' : openstack_keystone_authtoken
    'quattor' : openstack_quattor_heat
};