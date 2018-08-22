object template horizon;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_horizon_config;

"/metaconfig/module" = "horizon";

prefix "/metaconfig/contents";

"allowed_hosts" = list('*');
"openstack_keystone_url" = 'http://controller.mysite.com:5000/v3';
"caches/default" = dict(
    "LOCATION", list('controller.mysite.com:11211', 'controller.myothersite.com:11211'),
);
"openstack_keystone_multidomain_support" = true;
"time_zone" = "Europe/Brussels";
"secret_key" = "d5ae8703f268f0effff111";
"session_engine" = "django.contrib.sessions.backends.db";
"metadata_cache_dir" = "/var/cache/murano-dashboard";
"databases" = dict();

"websso_enabled" = true;
"websso_initial_choice" = "myidp_openid";
"websso_idp_mapping/myidp_openid" = list("myidp", "openid");
"websso_idp_mapping/myidp_mapped" = list("myidp", "mapped");
"websso_choices/credentials" = "Keystone Credentials";
"websso_choices/openid" =  "OpenID Connect";
"websso_choices/mapped" = "Security Assertion Markup Language";
"websso_choices/myidp_openid" = "Acme Corporation - OpenID Connect";
"websso_choices/myidp_mapped" = "Acme Corporation - SAML2";
"available_regions" = list(
    dict('url', 'http://controller.mysite.com:5000/v3', 'name', 'main'),
    dict('url', 'http://controller.myothersite.com:5000/v3', 'name', 'other'),
    );
