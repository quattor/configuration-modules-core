# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/identity/keystone;

@documentation {
    The Keystone "token" configuration section
}
type openstack_keystone_token = {
    @{Entry point for the token provider in the "keystone.token.provider"
    namespace. The token provider controls the token construction, validation,
    and revocation operations. Keystone includes "fernet" and "uuid" token
    providers. "uuid" tokens must be persisted (using the backend specified in
    the "[token] driver" option), but do not require any extra configuration or
    setup. "fernet" tokens do not need to be persisted at all, but require that
    you run "keystone-manage fernet_setup" (also see the "keystone-manage
    fernet_rotate" command)}
    'provider' : string = 'fernet' with match (SELF, '^(fernet|uuid)$')
    @{Entry point for the token persistence backend driver in the
    "keystone.token.persistence" namespace. Keystone provides "kvs" and "sql"
    drivers. The "kvs" backend depends on the configuration in the "[kvs]"
    section. The "sql" option (default) depends on the options in your
    "[database]" section. If you are using the "fernet" "[token] provider", this
    backend will not be utilized to persist tokens at all. (string value)}
    'driver' ? string with match (SELF, '^(sql|kvs)$')
} = dict();

@documentation {
    The Keystone configuration options in the "authtoken" Section
}
type openstack_keystone_authtoken = {
    include openstack_domains_common
    @{Complete "public" Identity API endpoint. This endpoint should not be an
    "admin" endpoint, as it should be accessible by all end users. Unauthenticated
    clients are redirected to this endpoint to authenticate. Although this
    endpoint should  ideally be unversioned, client support in the wild varies.
    If you are using a versioned v2 endpoint here, then this  should *not* be the
    same endpoint the service user utilizes  for validating tokens, because normal
    end users may not be  able to reach that endpoint. http(s)://host:port}
    'auth_uri' : type_absoluteURI
    @{Optionally specify a list of memcached server(s) to use for caching. If left
    undefined, tokens will instead be cached in-process ("host:port" list)}
    'memcached_servers' : type_hostport[]
};

@documentation {
    The Keystone configuration options in the "paste_deploy" Section.
}
type openstack_keystone_paste_deploy = {
    @{Deployment flavor to use in the server application pipeline.
    Provide a string value representing the appropriate deployment
    flavor used in the server application pipleline. This is typically
    the partial name of a pipeline in the paste configuration file with
    the service name removed.

    For example, if your paste section name in the paste configuration
    file is [pipeline:glance-api-keystone], set "flavor" to
    "keystone"}
    'flavor' : string = 'keystone'
} = dict();

@documentation {
Type that sets the OpenStack OpenRC script configuration
}
type openstack_openrc_config = {
    'os_username' : string = 'admin'
    'os_password' : string
    'os_project_name' : string = 'admin'
    'os_user_domain_name' : string = 'Default'
    'os_project_domain_name' : string = 'Default'
    'os_region_name' : string = 'RegionOne'
    'os_auth_url' : type_absoluteURI
    'os_identity_api_version' : long(1..) = 3
    'os_image_api_version' : long(1..) = 2
};

@documentation {
    The Keystone configuration sections
}
type openstack_keystone_config = {
    'DEFAULT' ? openstack_DEFAULTS
    'database' : openstack_database
    'token' : openstack_keystone_token
};
