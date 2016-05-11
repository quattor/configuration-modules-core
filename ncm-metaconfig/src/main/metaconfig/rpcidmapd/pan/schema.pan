declaration template metaconfig/rpcidmapd/schema;

include 'pan/types';

type rpcidmapd_general_config = {
    "Verbosity" ? long
    "Domain" : string
    "Local-Realms" ? string[]
};


type rpcidmapd_mapping_config = {
    "Nobody-User" : string = "nobody"
    "Nobody-Group" : string = "nobody"
} = nlist();


type rpcidmapd_translation_config = {
    "Method" : string = "nsswitch" with match(SELF, "^(nsswitch|umich_ldap|static)$")
    "GSS-Methods" ? string[]
} = nlist();

type rpcidmapd_umich_schema_config = {
    "LDAP_server" : type_fqdn # the.ldap.server
    "LDAP_base" : string # dc=local,dc=domain,dc=edu

    "LDAP_canonicalize_name" ? string # true
    "LDAP_people_base" ? string # <LDAP_base>
    "LDAP_group_base" ? string # <LDAP_base>
    "LDAP_use_ssl" ? boolean # false
    "LDAP_ca_cert" ? string # /etc/ldapca.cert
    "NFSv4_person_objectclass" ? string # NFSv4RemotePerson
    "NFSv4_name_attr" ? string # NFSv4Name
    "NFSv4_uid_attr" ? string # UIDNumber
    "GSS_principal_attr" ? string # GSSAuthName
    "NFSv4_acctname_attr" ? string # uid
    "NFSv4_group_objectclass" ? string # NFSv4RemoteGroup
    "NFSv4_gid_attr" ? string # GIDNumber
    "NFSv4_group_attr" ? string # NFSv4Name
    "NFSv4_member_attr" ? string # memberUID
};

type rpcidmapd_config = {
    "General" : rpcidmapd_general_config
    "Mapping" : rpcidmapd_mapping_config
    "Translation" : rpcidmapd_translation_config
    "Static" ? string{}{} # nlist of nlists: 1st key = REALM, 2nd key someuser, value = localuser, converted in someuser@REALM = localuser
    "UMICH_SCHEMA" ? rpcidmapd_umich_schema_config
};

