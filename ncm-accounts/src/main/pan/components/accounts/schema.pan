# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/accounts/schema;

include { 'quattor/schema' };

type structure_userinfo = {
    'comment'    ? string
    'homeDir'    ? string
    'createHome' ? boolean
    'createKeys' ? boolean
    'groups'     : string[]
    'password'   ? string
    'shell'      : string = '/bin/bash'
    'uid'        : long(0..)
    'poolStart'  ? long(0..)
    'poolDigits' ? long(1..)
    'poolSize'   ? long(0..)
    'info'       ? string{}
    'ldap'	 ? boolean
};

type structure_groupinfo = {
    'comment'    ? string
    'gid'        ? long(1..)
};

type structure_login_defs = {
    'uid_min' ? long(1..)
    'uid_max' ? long(1..)
    'gid_min' ? long(1..)
    'gid_max' ? long(1..)
    'pass_max_days' ? long(1..)
    'pass_min_days' ? long(1..)
    'pass_min_len' ? long(1..)
    'pass_warn_age' ? long(1..)
    'create_home' ? string with match (SELF,'yes|no')
    'mail_dir' ? string
    'umask' ? string
    'userdel_cmd' ? string
    'usergroups_enab' ? boolean
};

type component_accounts = {
    include structure_component
    'rootpwd'    ? string
    'rootshell'  ? string
    'shadowpwd'  ? boolean
    'users'      ? structure_userinfo{}
    'groups'     ? structure_groupinfo{}
    'login_defs' ? structure_login_defs
    'remove_unknown' : boolean = false
    # Really useful only if remove_uknown=true.
    # If system, only accounts/groups in the system range are preserved.
    # If dyn_user_group, accounts/groups below or equal to UID/GID_MAX are preserved.
    'preserved_accounts' : string = 'dyn_user_group' with match(SELF,'none|system|dyn_user_group')
    'kept_users' : string{}
    'kept_groups' : string{}
    'ldap'       ? boolean
};

bind '/software/components/accounts' = component_accounts;
