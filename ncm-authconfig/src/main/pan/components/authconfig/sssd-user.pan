# ${license-info}
# ${developer-info}
# ${author-info}

@{
    Contains the data structure describing the lookup for user and
    group accounts in the LDAP SSSD provider.

    Fields in these data types match the ldap_user_* and ldap_group_* fields in
}

declaration template components/authconfig/sssd-user;

type sssd_user = {
    "uid_number" : string = "uidNumber"
    "gid_number" : string = "gidNumber"
    "gecos" : string = "gecos"
    "home_directory" : string = "homeDirectory"
    "shell" : string = "loginShell"
    "uuid" : string = "nsUniqueId"
    "objectsid" ? string
    "modify_timestamp" : string = "modifyTimestamp"
    "shadow_last_change" : string = "shadowLastChange"
    "shadow_min" : string = "shadowMin"
    "shadow_max" : string = "shadowMax"
    "shadow_warning" : string = "shadowWarning"
    "shadow_inactive" : string = "shadowInactive"
    "shadow_expire" : string = "shadowExpire"
    "krb_last_pwd_change" : string = "krbLastPwdChange"
    "krb_password_expiration" : string = "krbPasswordExpiration"
    "ad_account_expires" : string = "accountExpires"
    "ad_user_account_control" : string = "userAccountControl"
    "nds_login_disabled" : string = "loginDisabled"
    "nds_login_expiration_time" : string = "loginDisabled"
    "nds_login_allowed_time_map" : string = "loginAllowedTimeMap"
    "principal" : string = "krbPrincipalName"
    "ssh_public_key" ? string
    "fullname" : string = "cn"
    "member_of" : string = "memberOf"
    "authorized_service" : string = "authorizedService"
    "authorized_host" : string = "host"
    "search_base" ? string
    "search_filter" ? string
};



type sssd_group = {
    "object_class" : string = "posixGroup"
    "name" : string = "cn"
    "gid_number" : string = "gidNumber"
    "member" : string = "memberuid"
    "uuid" : string = "nsUniqueId"
    "objectsid" ? string
    "modify_timestamp" : string = "modifyTimestamp"
    "nesting_level" : long = 2
    "search_base" ? string
    "search_filter" ? string
};
