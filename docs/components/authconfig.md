### NAME

authconfig: NCM component to manage system authentication services

### DESCRIPTION

The _authconfig_ component manages the system authentication methods
on RedHat systems using the "authconfig" command.  In addition, is can
set additional operational parameters for LDAP authentication by
modifying the `/etc/ldap.conf` (SL5) or the `/etc/nslcd.conf` (SL6) files
directly.  It will also enable/disable NSCD support on the client.

### RESOURCES

#### `/software/components/authconfig/safemode`

When set to true, no actual configuration will change.
Default: false.

#### `/software/components/authconfig/usecache`

Enable or disable nscd operation

#### `/software/components/authconfig/usemd5`

Enable the use of MD5 hashed password

#### `/software/components/authconfig/useshadow`

Enable the use of shadow password files

#### `/software/components/authconfig/method`

Named list (nlist) of authentication methods to enable. Supported
methods are: files, ldap, nis, krb5, smb, hesiod and afs.
Note that "afs" is only supported on the CERN-modified version of
authconfig. Also, "files" cannot be disabled.

#### `/software/components/authconfig/method/{}/enable`

Enable of disable this method. Unlisted methods are 
always disabled.

### SEE ALSO

[https://twiki.cern.ch/twiki/bin/view/ELFms/ELFmsZuul](https://twiki.cern.ch/twiki/bin/view/ELFms/ELFmsZuul)

### EXAMPLE

    include  pro_declaration_component_authconfig;

    "/software/components/authconfig/active" = true;

    "/software/components/authconfig/safemode" = false;

    "/software/components/authconfig/usemd5" = true;
    "/software/components/authconfig/useshadow" = true;
    "/software/components/authconfig/usecache" = true;
    "/software/components/authconfig/startstop" = true;

    "/software/components/authconfig/method/files/enable" = true;

    ###  "/software/components/authconfig/method/afs/enable" = true;
    ###  "/software/components/authconfig/method/afs/cell" = "cern.ch";

    "/software/components/authconfig/method/ldap/enable" = false;
    "/software/components/authconfig/method/ldap/nssonly" = false;
    "/software/components/authconfig/method/ldap/conffile" = "/etc/ldap.conf";
    "/software/components/authconfig/method/ldap/servers" = list ( "tbn06.nikhef.nl" , "hooimijt.nikhef.nl" );
    "/software/components/authconfig/method/ldap/basedn" = "dc=farmnet,dc=nikhef,dc=nl";
    "/software/components/authconfig/method/ldap/tls/enable" = true;
    "/software/components/authconfig/method/ldap/binddn" = "cn=proxyuser,dc=example,dc=com";
    "/software/components/authconfig/method/ldap/bindpw" = "secret";
    "/software/components/authconfig/method/ldap/rootbinddn" = "cn=manager,dc=example,dc=com";
    "/software/components/authconfig/method/ldap/port" = 389;
    "/software/components/authconfig/method/ldap/timeouts/idle" = 3600;
    "/software/components/authconfig/method/ldap/timeouts/bind" = 30;
    "/software/components/authconfig/method/ldap/timeouts/search" = 30;
    "/software/components/authconfig/method/ldap/pam_filter" = "|(gid=1012)(gid=1013)";
    "/software/components/authconfig/method/ldap/pam_login_attribute" = "uid";
    "/software/components/authconfig/method/ldap/pam_groupdn" = "cn=SystemAdministrators,ou=DirectoryGroups,dc=farmnet,dc=nikhef,dc=nl";
    "/software/components/authconfig/method/ldap/pam_member_attribute" = "uniquemember";
    "/software/components/authconfig/method/ldap/tls/peercheck" = "yes";

    ###  "/software/components/authconfig/method/ldap/tls/cacertfile" = undef;
    ###  "/software/components/authconfig/method/ldap/tls/cacertdir" = undef;
    ###  "/software/components/authconfig/method/ldap/tls/ciphers" = undef;

    "/software/components/authconfig/method/ldap/nss_base_passwd" = "OU=Users,OU=Organic Units,DC=cern,DC=ch";
    "/software/components/authconfig/method/ldap/nss_base_group" = "OU=SLC,OU=Workgroups,DC=cern,DC=ch";
    "/software/components/authconfig/method/ldap/bind_policy" = "soft";
    "/software/components/authconfig/method/ldap/nss_map_objectclass/posixAccount" = "user";
    "/software/components/authconfig/method/ldap/nss_map_objectclass/shadowAccount" = "user";
    "/software/components/authconfig/method/ldap/nss_map_objectclass/posixGroup" = "group";
    "/software/components/authconfig/method/ldap/nss_map_attribute/uid" = "sAMAccountName";
    "/software/components/authconfig/method/ldap/nss_map_attribute/homeDirectory" = "unixHomeDirectory";
    "/software/components/authconfig/method/ldap/nss_map_attribute/uniqueMember" = "member";
    "/software/components/authconfig/method/ldap/pam_login_attribute" = "sAMAccountName";
    "/software/components/authconfig/method/ldap/ssl" = "start_tls";

    ###  "/software/components/authconfig/method/ldap/pam_min_uid" = "0"; ### NOT IMPLEMENTED #
    ###  "/software/components/authconfig/method/ldap/pam_max_uid" = "0";### NOT IMPLEMENTED #

    "/software/components/authconfig/method/nis/enable" = false;
    "/software/components/authconfig/method/nis/domain" = "nikhef.nl";
    "/software/components/authconfig/method/nis/servers" = list ( "ajax.nikhef.nl" );

    "/software/components/authconfig/method/krb5/enable" = false;
    "/software/components/authconfig/method/krb5/kdcs" = list ( "kdc.nikhef.nl" );
    "/software/components/authconfig/method/krb5/adminserver" = list ( "krbadmin.nikhef.nl" );
    "/software/components/authconfig/method/krb5/realm" = "NIKHEF.NL";

    "/software/components/authconfig/method/smb/enable" = false;
    "/software/components/authconfig/method/smb/workgroup" = "NIKHEF";
    "/software/components/authconfig/method/smb/servers" = list ( "paling.nikhef.nl" );

    "/software/components/authconfig/method/hesiod/enable" = false;
    "/software/components/authconfig/method/hesiod/lhs" = "lefthanded";
    "/software/components/authconfig/method/hesiod/rhs" = "righthanded";
