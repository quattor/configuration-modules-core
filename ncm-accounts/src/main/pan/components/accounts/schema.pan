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
    'groups'     ? string[]
    'password'   ? string
    'shell'      ? string
    'uid'        ? long(1..)
    'poolStart'  ? long(0..)
    'poolDigits' ? long(1..)
    'poolSize'   ? long(0..)
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
};

type component_accounts = {
    include structure_component
    'rootpwd'    ? string
    'shadowpwd'  ? boolean
    'users'      ? structure_userinfo{}
    'groups'     ? structure_groupinfo{}
    'login_defs' ? structure_login_defs
    'remove_unknown' ? boolean
    'kept_users' ? string{}
    'kept_groups' ? string{}
};

bind '/software/components/accounts' = component_accounts;
