# ${license-info}
# ${developer-info}
# ${author-info}

@{
    Contains the data structure describing the lookup for user and
    group accounts in the LDAP SSSD provider.

    Fields in these data types match the ldap_user_* and ldap_group_* fields in
}

declaration template components/authconfig/sssd/user;

type sssd_user = {
    "object_class" : string = "posixAccount"
    "uid_number" ? string
    "gid_number" ? string
    "name" ? string
    "gecos" ? string
    "home_directory" ? string
    "shell" ? string
    "uuid" ? string
    "objectsid" ? string
    "modify_timestamp" ? string
    "shadow_last_change" ? string
    "shadow_min" ? string
    "shadow_max" ? string
    "shadow_warning" ? string
    "shadow_inactive" ? string
    "shadow_expire" ? string
    "krb_last_pwd_change" ? string
    "krb_password_expiration" ? string
    "ad_account_expires" ? string
    "ad_user_account_control" ? string
    "nds_login_disabled" ? string
    "nds_login_expiration_time" ? string
    "nds_login_allowed_time_map" ? string
    "principal" ? string
    "ssh_public_key" ? string
    "fullname" ? string
    "member_of" ? string
    "authorized_service" ? string
    "authorized_host" ? string
    "search_base" ? string
    "search_filter" ? string
};



type sssd_group = {
    "object_class" : string = "posixGroup"
    "name" ? string = "cn"
    "gid_number" ? string
    "member" ? string
    "uuid" ? string
    "objectsid" ? string
    "modify_timestamp" ? string
    "nesting_level" ? long
    "search_base" ? string
    "search_filter" ? string
};
