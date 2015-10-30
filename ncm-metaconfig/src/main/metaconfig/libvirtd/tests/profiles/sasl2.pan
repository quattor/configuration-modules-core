object template sasl2;

include 'metaconfig/libvirtd/sasl2';

prefix "/software/components/metaconfig/services/{/etc/sasl2/libvirt.conf}/contents";
"mech_list" = 'gssapi';
"keytab" = '/etc/libvirt/krb5.tab';
"sasldb_path" = '/etc/libvirt/passwd.db';
