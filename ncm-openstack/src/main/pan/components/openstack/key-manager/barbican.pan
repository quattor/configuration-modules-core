# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/key-manager/barbican;

include 'components/openstack/identity';

type openstack_barbican_secretstore_plugin = choice('store_crypto', 'kmip_crypto', 'dogtag_crypto');

@documentation{
    Barbican default section
}
type openstack_barbican_DEFAULTS = {
    include openstack_DEFAULTS
    @{SQLAlchemy connection string for the reference implementation
    registry server. Any valid SQLAlchemy connection string is fine.
    For some weird reason Barbican does not use the [database] section}
    'sql_connection' : string
    @{Host name, for use in HATEOAS-style references. Note: Typically this
    would be the load balanced endpoint that clients would use to
    communicate back with this service. If a deployment wants to derive
    host from wsgi request instead then make this blank. Blank is needed
    to override default config value which is 'http://localhost:9311'}
    'host_href' ? type_absoluteURI = "http://localhost:9311"
};

@documentation{
    Barbican secretstore section
}
type openstack_barbican_secretstore = {
    @{Extension namespace to search for plugins}
    'namespace' : string = 'barbican.secretstore.plugin'
    @{List of secret store plugins to load}
    'enabled_secretstore_plugins' : openstack_barbican_secretstore_plugin[] = list('store_crypto')
};

@documentation{
    Barbican crypto section
}
type openstack_barbican_crypto = {
    @{List of crypto plugins to load}
    'enabled_crypto_plugins' : string[] = list('simple_crypto')
};

@documentation{
    Barbican simple_crypto_plugin section
}
type openstack_barbican_simple_crypto_plugin = {
    @{Extension namespace to search for plugins}
    'namespace' : string = 'barbican.crypto.plugin'
    @{Key encryption key to be used by Simple Crypto Plugin.
    It should be a 32-byte value which is base64 encoded (openssl rand -base64 32)}
    'kek' : string
};

@documentation{
    Barbican certificate section
}
type openstack_barbican_certificate = {
    @{Extension namespace to search for plugins}
    'namespace' : string = 'barbican.certificate.plugin'
    @{List of certificate plugins to load}
    'enabled_certificate_plugins' : string[] = list('dogtag')
};

@documentation{
    Barbican dogtag_plugin section
}
type openstack_barbican_dogtag_plugin = {
    @{Path to PEM file for authentication}
    'pem_path' : absolute_file_path
    @{Hostname for the Dogtag instance}
    'dogtag_host' : type_hostname
    @{Port for the Dogtag instance}
    'dogtag_port' : type_port = 8443
    @{Path to the NSS certificate database}
    'nss_db_path' : absolute_file_path = '/etc/barbican/alias'
    'nss_db_path_ca' ? absolute_file_path
    @{Password for the NSS certificate databases}
    'nss_password' : string
    @{Profile for simple CMC requests}
    'simple_cmc_profile' : string = 'caOtherCert'
    @{Time in days for CA entries to expire}
    'ca_expiration_time' ? long(1..)
    @{Working directory for Dogtag plugin}
    'plugin_working_dir' ? absolute_file_path
};

@documentation{
    Barbican kmip_plugin section
}
type openstack_barbican_kmip_plugin = {
    @{Username for authenticating with KMIP server}
    'username' : string = 'admin'
    @{Password for authenticating with KMIP server}
    'password' : string
    @{Address of the KMIP server}
    'host' : type_hostname
    @{Port for the KMIP server}
    'port' : type_port = '5696'
    @{File path to local client certificate keyfile}
    'keyfile' : absolute_file_path
    @{File path to local client certificate}
    'certfile' : absolute_file_path
    @{File path to concatenated "certification authority" certificates}
    'ca_certs' : absolute_file_path
};

type openstack_quattor_barbican = openstack_quattor;

@documentation{
    list of Barbican configuration sections
}
type openstack_barbican_config = {
    'DEFAULT' : openstack_barbican_DEFAULTS
    'keystone_authtoken' : openstack_keystone_authtoken
    'secretstore' : openstack_barbican_secretstore
    'crypto' ? openstack_barbican_crypto
    'simple_crypto_plugin' ? openstack_barbican_simple_crypto_plugin
    'certificate' ? openstack_barbican_certificate
    'dogtag_plugin' ? openstack_barbican_dogtag_plugin
    'kmip_plugin' ? openstack_barbican_kmip_plugin
    'quattor' : openstack_quattor_barbican
};
