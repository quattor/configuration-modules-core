# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/identity/keystone;

@documentation{
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

@documentation{
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
    @{The region in which the service server can be found}
    'region_name' ? string = 'RegionOne'
};

@documentation{
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


@documentation{
     The Keystone configuration options in the "auth" section
}
type openstack_keystone_auth = {
    @{Allowed authentication methods. Note: You should disable the `external` auth
      method if you are currently using federation. External auth and federation
      both use the REMOTE_USER variable. Since both the mapped and external plugin
      are being invoked to validate attributes in the request environment, it can
      cause conflicts.}
    'methods' ? choice('external', 'password', 'token', 'oauth1', 'mapped', 'openid')[]
};

@documentation{
     The Keystone configuration options in the "federation" section
}
type openstack_keystone_federation = {
    @{Prefix to use when filtering environment variable names for federated
      assertions. Matched variables are passed into the federated mapping engine.}
    'assertion_prefix' ? string

    @{Value to be used to obtain the entity ID of the Identity Provider from the
      environment. For mod_shib, this would be Shib-Identity-Provider.
      For mod_auth_openidc, this could be HTTP_OIDC_ISS. For mod_auth_mellon
      this could be MELLON_IDP.
      It is recommended to set this in the per-protocol basis}
    'remote_id_attribute' ? string

    # TODO: only one supported for now. For whatever reason keystone relies on duplicate properties for this one
    @{A list of trusted dashboard hosts. Before accepting a Single Sign-On request
      to return a token, the origin host must be a member of this list. This
      configuration option may be repeated for multiple values. You must set this
      in order to use web-based SSO flows.}
    'trusted_dashboard' ? type_hostURI[] with length(SELF) == 1

    @{Absolute path to an HTML file used as a Single Sign-On callback handler. This
      page is expected to redirect the user from keystone back to a trusted
      dashboard host, by form encoding a token in a POST request. Keystone's
      default value /etc/keystone/sso_callback_template.html should be sufficient for most deployments.}
    'sso_callback_template' ? absolute_file_path
};

@documentation{
     The Keystone configuration options in the "mapped" section
}
type openstack_keystone_mapped = {
    @{Value to be used to obtain the entity ID of the Identity Provider from the
      environment. For mod_shib, this would be Shib-Identity-Provider.}
    'remote_id_attribute' ? string
};

@documentation{
     The Keystone configuration options in the "openid" section
}
type openstack_keystone_openid = {
    @{Value to be used to obtain the entity ID of the Identity Provider from the
      environment. For mod_auth_openidc, this could be HTTP_OIDC_ISS.}
    'remote_id_attribute' ? string
};

type openstack_quattor_keystone = openstack_quattor;

@documentation{
    The Keystone configuration sections
}
type openstack_keystone_config = {
    'DEFAULT' ? openstack_DEFAULTS
    'database' : openstack_database
    'token' : openstack_keystone_token
    'auth' ? openstack_keystone_auth
    'federation' ? openstack_keystone_federation
    'mapped' ? openstack_keystone_mapped
    'openid' ? openstack_keystone_openid
    'quattor' : openstack_quattor_keystone
};
