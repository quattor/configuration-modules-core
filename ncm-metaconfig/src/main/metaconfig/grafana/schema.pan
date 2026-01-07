declaration template metaconfig/grafana/schema;

include 'pan/types';

type grafana_server = {
    'http_port' ? string = "3000"
    # The public facing domain name used to access grafana from a browser
    'domain' ? string
    # The full public facing url you use in browser, used for redirects and emails
    # If you use reverse proxy and sub path specify full url (with sub path)
    'root_url' ? string
};
type grafana_database = {
    'type' : choice('sqlite3', 'postgres', 'mysql') = 'sqlite3'
    'host' ? string
    'name' ? string
    'user' ? string
    'password' ? string
    # Set to true or false to enable or disable high availability mode.
    # When it's set to false some functions will be simplified and only run in-process
    # instead of relying on the database.
    #
    # Only set it to false if you run only a single instance of Grafana.
    'high_availability' ? boolean = false
    # For "sqlite3" only, path relative to data_path setting
    'path' ? string = 'grafana.db'

};
type grafana_security = {
    # disable creation of admin user on first start of grafana
    'disable_initial_admin_creation' : boolean = false

    # default admin user, created on startup
    'admin_user' : string = 'admin'

    # default admin password, can be changed before first start of grafana,  or in profile settings
    'admin_password' : string = 'admin'

    # default admin email, created on startup
    'admin_email' : string = 'admin@localhost'
    # set to true if you host Grafana behind HTTPS
    'cookie_secure' : boolean = false
};

type grafana_dashboards = {
    # Number dashboard versions to keep (per dashboard). Default: 20, Minimum: 1
    'versions_to_keep' : long(1..) = 20

    # Path to the default home dashboard. If this value is empty, then Grafana uses StaticRootPath + "dashboards/home.json"
    'default_home_dashboard_path' ? string
};

type grafana_users = {
    # disable user signup / registration
    'allow_sign_up' ? boolean = false

    # Allow non admin users to create organizations
    'allow_org_create' ? boolean = false

    # Set to true to automatically assign new users to the default organization (id 1)
    'auto_assign_org' ? boolean = false

    # Set this value to automatically add new users to the provided organization (if auto_assign_org above is set to true)
    'auto_assign_org_id' ? long(1..) = 1

    # Default role new users will be automatically assigned
    'auto_assign_org_role' ? choice('Viewer', 'Editor', 'Admin') = 'Viewer'

    # Require email validation before sign up completes
    'verify_email_enabled' ? boolean = false
};

type grafana_auth = {
    # Set to true to disable (hide) the login form, useful if you use OAuth, defaults to false
    'disable_login_form' ? boolean = false

    # Set to true to disable the sign out link in the side menu. Useful if you use auth.proxy or auth.jwt, defaults to false
    'disable_signout_menu' ? boolean = false
};

type grafana_auth_proxy = {
    'enabled' ? boolean = false
    'header_name' ? string = 'X-WEBAUTH-USER'
    'header_property' ? string = 'username'
    'auto_sign_up' ? boolean = true
    'whitelist' ? list()
    'headers' ? string = 'Email:X-User-Email, Name:X-User-Name'
    # Non-ASCII strings in header values are encoded using quoted-printable encoding
    'headers_encoded' ? boolean = false
    # Read the auth proxy docs for details on what the setting below enables
    'enable_login_token' ? boolean = false
};

type grafana_smtp = {
    'enabled' ? boolean = false
    'host' ? string
    'user' ? string
    # If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
    'password' ? string
    'cert_file' ? absolute_file_path
    'key_file' ? absolute_file_path
    'skip_verify' ? boolean = false
    'from_address' ? string = 'admin@grafana.localhost'
    'from_name' ? string = 'Grafana'
    # EHLO identity in SMTP dialog (defaults to instance_name)
    'ehlo_identity' ? string
    # SMTP startTLS policy (defaults to 'OpportunisticStartTLS')
    'startTLS_policy' ? string
    # Enable trace propagation in e-mail headers, using the 'traceparent', 'tracestate' and (optionally) 'baggage' fields (defaults to false)
    'enable_tracing' ? string
};
type grafana_external_image_storage = {
    # Used for uploading images to public servers so they can be included in slack/email messages.
    'provider' ? choice('s3', 'webdav', 'gcs', 'azure_blob', 'local')
};

type grafana_plugins = {
    'enable_alpha' ? boolean = false
    'app_tls_skip_verify_insecure' ? boolean = false
    # Enter a comma-separated list of plugin identifiers to identify plugins to load even if they are unsigned. Plugins with modified signatures are never loaded.
    'allow_loading_unsigned_plugins' ? list()
    # Enable or disable installing / uninstalling / updating plugins directly from within Grafana.
    'plugin_admin_enabled' ? boolean = false
    # Log all backend requests for core and external plugins.
    'log_backend_requests' ? boolean = false
    # Disable download of the public key for verifying plugin signature.
    'public_key_retrieval_disabled' ? boolean = false
    # Force download of the public key for verifying plugin signature on startup. If disabled, the public key will be retrieved every 10 days.
    # Requires public_key_retrieval_disabled to be false to have any effect.
    'public_key_retrieval_on_startup' ? boolean = false
    # Enter a comma-separated list of plugin identifiers to avoid loading (including core plugins). These plugins will be hidden in the catalog.
    'disable_plugins' ? boolean = false
};



type grafana_ini = {
    "server" ? grafana_server
    "database" ? grafana_database
    "security" ? grafana_security
    "users" ? grafana_users
    "auth" ? grafana_auth
    "auth.proxy" ? grafana_auth_proxy
    "smtp" ? grafana_smtp
    "external_image_storage" ? grafana_external_image_storage
    "plugins" ? grafana_plugins
};
