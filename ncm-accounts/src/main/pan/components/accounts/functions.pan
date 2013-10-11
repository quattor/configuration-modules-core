# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/accounts/functions;

variable ACCOUNTS_USER_HOME_ROOT ?= '/home';
variable ACCOUNTS_USER_CREATE_HOME ?= true;
variable ACCOUNTS_USER_AUTOGROUP ?= true;
variable ACCOUNTS_USER_CHECK_GROUP ?= true;
variable ACCOUNTS_IGNORE_MISSING_GROUPS ?= false;
variable ACCOUNTS_USER_COMMENT ?= 'Created by ncm-accounts';
variable ACCOUNTS_GROUP_COMMENT ?= 'Created by ncm-accounts';


# create_group(groupname:string,
#             params:structure_groupinfo)

#
# Return value : structure_account
#
# Create a group, applying some defaults defined by variables and checking
# information consistency (e.g. group existence).
#

function create_group = {
    function_name = 'create_group';

    if ( ARGC != 2 || ! is_nlist(ARGV[1]) ) {
        error(function_name + ' requires 2 argument (string,nlist)');
    };
    groupname = ARGV[0];
    group_params = ARGV[1];

    if ( !exists(SELF) ) {
        error(function_name + " : /software/components/accounts doesn't exist");
    };
    accounts = SELF;

    if ( !exists(group_params['comment']) && exists(ACCOUNTS_group_COMMENT) ) {
        group_params['comment'] = ACCOUNTS_group_COMMENT;
    };

    accounts['groups'][groupname] = group_params;

    accounts;
};

# create_user(username:string,
#             params:structure_userinfo)

#
# Return value : structure_account
#
# Create a user, applying some defaults defined by variables and checking
# information consistency (e.g. group existence).
#

function create_user = {
    function_name = 'create_user';

    if ( ARGC != 2 || ! is_nlist(ARGV[1]) ) {
        error(function_name + ' requires 2 argument (string,nlist)');
    };
    username = ARGV[0];
    user_params = ARGV[1];

    if ( !exists(SELF) ) {
        error(function_name + " : /software/components/accounts doesn't exist");
    };
    accounts = SELF;

    if ( !exists(user_params['homeDir']) &&
         exists(ACCOUNTS_USER_HOME_ROOT) &&
         is_defined(username) ) {
        user_params['homeDir'] = ACCOUNTS_USER_HOME_ROOT + '/' + username;
    };

    if ( !exists(user_params['createHome']) &&
          exists(ACCOUNTS_USER_CREATE_HOME) &&
          exists(user_params['homeDir']) ) {
        user_params['createHome'] = ACCOUNTS_USER_CREATE_HOME;
    };

    if ( !exists(user_params['password']) && exists(ACCOUNTS_USER_PWD) ) {
        user_params['password'] = ACCOUNTS_USER_PWD;
    };

    if ( !exists(user_params['comment']) && exists(ACCOUNTS_USER_COMMENT) ) {
        user_params['comment'] = ACCOUNTS_USER_COMMENT;
    };

    if ( !exists(user_params['groups']) ) {
        if ( ACCOUNTS_USER_AUTOGROUP && is_defined(username)) {
            user_params['groups'] = list(username);
        };
    };

    if ( exists(user_params['groups']) && ACCOUNTS_USER_CHECK_GROUP ) {
        ok = first(user_params['groups'], i, groupname);
        while (ok) {
            if ( !exists(accounts['groups'][groupname]) ) {
                if ( groupname == username &&
                     exists(user_params['uid']) &&
                     !exists(user_params['poolStart']) ) {
                    accounts = create_group(groupname,nlist('gid',user_params['uid']));
                } else {
                    if  (ACCOUNTS_IGNORE_MISSING_GROUPS) {
                        delete(user_params['groups'][i]);
                    } else {
                        error(function_name + " : group \"" + groupname + "\" doesn't exist");
                    };
                };
            };
            ok = next(user_params['groups'], i, groupname);
        };
    };

    accounts['users'][username] = user_params;

    accounts;
};


# create_accounts_from_db(userList:nlist,
#                      users:list:optional,
#                      accountType:optional)
#
# Return Value : structure_accounts
#
# Function to create users or groups from a nlist containing user or group characteristics.
# User/group characteristics must be provided as structure_userinfo/structure_groupinfo.
#
# Second parameter, if presents, gives the list of users to create from user_list.
# This allows to use a unique user/group definition for all nodes, to warrant consistency
# between nodes.
#
# By default - accountType undefined or 0, this function creates user accounts.
# To create groups, set third parameter (accountType) to 1.

function create_accounts_from_db = {
    function_name = 'create_accounts';
    if ( ARGC < 1 || ARGC > 3 || ! is_nlist(ARGV[0]) ) {
        error(function_name + ' requires at least 1 argument (nlist)');
    };
    accounts_db = ARGV[0];

    if ( ARGC >= 2 && is_defined(ARGV[1]) ) {
        account_list = ARGV[1];
        if ( ! is_list(account_list) ) {
            error(function_name + ' second argument must be a list');
        };
    } else {
        account_list = undef;
    };

    if ( ARGC >=3 && (ARGV[2] == 1) ) {
       accountType = 'group';
    } else {
       accountType = 'user';
    };

    if ( !exists(SELF) ) {
        error(function_name + " : /software/components/accounts doesn't exist");
    };
    accounts = SELF;

    # TODO : test existence of account and retrieve existing chars (merge with new)
    if ( is_defined(account_list) ) {
        ok = first(account_list, i, accountname);
        while (ok) {
            if ( !exists(accounts_db[accountname]) ) {
                error(function_name + ': ' + accountname + ' not found in ' + accountType + ' list');
            };
            if ( accountType == 'user' ) {
                accounts = create_user(accountname,accounts_db[accountname]);
            } else {
                accounts = create_group(accountname,accounts_db[accountname]);
            };
       	    ok = next(account_list, i, accountname);
        };
    } else {
        ok = first(accounts_db, accountname, account_params);
        while (ok) {
            if ( accountType == 'user' ) {
                accounts = create_user(accountname,accounts_db[accountname]);
            } else {
                accounts = create_group(accountname,accounts_db[accountname]);
            };
            ok = next(accounts_db, accountname, account_params);
        };
    };

    accounts;
};


# keep_user_group(user_or_group)
#
# Return value : kept_users or kept_groups structure
#
# Add a user or group (string) or list of users or groups (list of strings) to the 
# kept_users or kept_groups resource. 
# If the user/group is already present in the list, it is ignored but it
# doesn't cause an error.
#

function keep_user_group = {
    function_name = 'keep_user_group';

    if ( (ARGC != 1) || (!is_string(ARGV[0]) && !is_list(ARGV[0])) ) {
        error(function_name + ' requires 1 argument (string or list of strings)');
    };
    
    if ( is_string(ARGV[0]) ) {
      tmp = ARGV[0];
      ARGV[0] = undef;
      ARGV[0] = list(tmp);
    };
    
    foreach (i;v;ARGV[0]) {
      SELF[v] = '';
    };

    SELF;
};


#
# test if user or group is defined in either users/groups or kept_users/groups
# first argument is the name, 2nd argument type (user or group)
#
function is_user_or_group = {
    if (( ARGC != 2) || ! is_string(ARGV[0]) || ! (ARGV[1] == 'user'|ARGV[1] == 'group')) {
        error("is_user_or_group expects 2 arguments : first the name as a string; 2nd the type (user or group)");
    };
    path = format("/software/components/accounts/%ss/%s", ARGV[1], ARGV[0]);
    keptpath=format("/software/components/accounts/kept_%ss/%s", ARGV[1], ARGV[0]);
    return exists(path) || exists(keptpath);
};

# type to be used in schema of other components
type defined_user = string with is_user_or_group(SELF, "user");
type defined_group = string with is_user_or_group(SELF, "group");
