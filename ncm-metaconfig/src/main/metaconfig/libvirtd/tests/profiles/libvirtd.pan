object template libvirtd;

include 'metaconfig/libvirtd/schema';

bind "/software/components/metaconfig/services/{/etc/libvirt/libvirtd.conf}/contents" = structure_component_libvirtd;

prefix "/software/components/metaconfig/services/{/etc/libvirt/libvirtd.conf}";
"network" = dict(
    "listen_tls", 0,
    "listen_tcp", 1,
);
"authn" = dict(
    "auth_tcp", "sasl",
    "auth_tls", "none",
);
"authz" = dict(
    "sasl_allowed_username_list", list('libvirt/*.domain.org'),
);
