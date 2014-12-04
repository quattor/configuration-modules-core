---
layout: documentation
title: accounts
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

ncm-accounts: NCM component to manage the local accounts on the machine.

### DESCRIPTION

The _accounts_ component manages the local accounts on a machine. LDAP
authentication depends on the LDAP configuration, which is handled by
[ncm-authconfig](https://metacpan.org/pod/ncm-authconfig).

Shadowing of passwords is also controlled by [ncm-authconfig](https://metacpan.org/pod/ncm-authconfig).

### FUNCTIONS

accounts provides several functions as an API to handle creation of users and groups.
They are mainly targeted at helping creating consistent accounts across machines,
using a central definition of all accounts and a per machine list of accounts to be
actually created.

All these functions update a structure\_accounts (return value may be assigned to
"/software/components/accounts").

Behaviour of these functions can be customized by definining some variables before
calling them, mainly :

- ACCOUNTS\_USER\_HOME\_ROOT

    defines default root for home directory (D: `/home`)

- ACCOUNTS\_USER\_CREATE\_HOME

    defines if home directory must be created by default (D : true)

- ACCOUNTS\_USER\_AUTOGROUP

    defines if a group must be defined with the same name as the user, if no group
    has been explicitly specified (D: true).

- ACCOUNTS\_USER\_CHECK\_GROUP

    defines if the default group must be created if it doesn't exist, with a gid
    equals to uid (D: true)

- ACCOUNTS\_USER\_COMMENT

    defines a default value for user comment (D: "Created by ncm-accounts")

- ACCOUNTS\_GROUP\_COMMENT

    defines a default value for group comment (D: "Created by ncm-accounts")

#### create\_accounts\_from\_db(userList:nlist, users:list:optional, accountType:optional)

This function creates users or groups from a nlist containing user or group characteristics.
It updates a structure\_accounts (return value may be assigned to "/software/components/accounts").

User/group characteristics must be provided as structure\_userinfo/structure\_groupinfo.

Second parameter, if presents, gives the list of users to create from user\_list.
This allows to use a unique user/group definition for all nodes, to warrant consistency
between nodes.

By default (accountType undefined or 0), this function creates user accounts.
To create groups, set third parameter (accountType) to 1.

#### create\_group(groupname:string, params:structure\_groupinfo)

This function creates a group, applying some defaults defined by variables and checking
information consistency.
It updates a structure\_accounts (return value may be assigned to "/software/components/accounts").

#### create\_user(username:string, params:structure\_userinfo)

This function creates a user, applying some defaults defined by variables and checking
 information consistency (e.g. group existence).
It updates a structure\_accounts (return value may be assigned to "/software/components/accounts").

#### keep\_user\_group(user\_or\_group:string or list of string)

This functions adds a user or group to the kept\_users or kept\_groups resources. The
argument can be a string or list of strings. The return value can be assigned to 
`/software/components/accounts/kept`\_users or `/software/components/accounts/kept`\_groups.

### RESOURCES

#### `/software/components/accounts/rootpwd`

The crypted root password for the machine.

#### `/software/components/accounts/users`

An nlist of users to configure on the node.  The key is the account
name (or base name for pool accounts). The numerical UID is
mandatory. The available fields are:

- comment

    real name or comment about user.  Defaults to user name itself.

- homeDir

    full path of the home directory of the user.  Defaults
    to the system default. For pool accounts this will be used as a
    base for creating numbered home directories; if this is not set
    the username will be used as a base.

- createHome

    boolean indicating whether to create a home directory for the user.
    Defaults to false.

- groups

    a list of groups for this user.  The first group listed
    is the primary group.  If this is not given, then it will default to a
    group named identically to the user name. NOTE: If this group already
    exists, then the command to add the user will fail.

- password

    the crypted password entry for the user.  No
    default. If not given it will result in a locked account, except if
    the account already exists and has a defined password: in this case, it will
    be kept.

- shell

    the shell for the user. If it is defined as an empty string, the current shell
    is preserved for an existing account (for a new account, it will remain undefined,
    meaning that the default shell on the system will be used). 

    Defaults to `/bin/bash.`

- uid

    the uid value for this account. Mandatory. This is interpreted as the
    base uid value for pool accounts (i.e. poolSize > 0).

- poolStart

    the index at which to start the pool accounts.  The
    default is 0.  This must be a non-negative number.

- poolDigits

    the number of digits to which the pool account
    numbers are padded. For example a value of 3 will create accounts
    atlas000, atlas001, etc. The default is the number of digits in the
    highest-numbered pool account.

- poolSize

    number of pool accounts to create.  The default is
    0 which indicates that it is a normal (unique) account.  A value
    greater than 0 will create a set of numbered accounts with the given
    user name as a base.  E.g. a base name of "atlas" and a poolSize=3
    will create three accounts atlas0 atlas1 atlas2.

#### `/software/components/accounts/groups`

An nlist of groups to configure on the node.  The key is the group
name.  At least one field must be specified.

- comment

    ignored, but provided so gid doesn't have to be

- gid

    the optional gid number for the group

#### `/software/components/accounts/login`\_defs

A nlist of values to be set in `/etc/login.defs`. NOTE: This
configuration file is specific to RedHat-like systems; setting will be
ignored on other systems.  This file configures all kinds of default
settings such as:

- uid\_min, uid\_max

    Min/max values for automatic uid selection in useradd

- gid\_min, gid\_max

    Min/max values for automatic gid selection in groupadd

- pass\_max\_days

    Maximum number of days a password may be used.

- pass\_min\_days

    Minimum number of days allowed between password changes.

- pass\_min\_len

    Minimum acceptable password length.

- pass\_warn\_age

    Number of days warning given before a password expires.

- create\_home

    If useradd should create home directories for users by default

#### `/software/components/accounts/remove`\_unknown

Flag to indicate whether unknown accounts should be deleted.  The
default is false.  The root account can never be removed.

#### `/software/components/accounts/preserved`\_accounts

This property may have 3 values: 'none', 'system', 'dyn\_user\_group'. It controls
the accounts/groups that have to be preserved when 'remove\_unknown' is true 
(it has no effect when remove\_unknown=false).

The effect of each possible value is

    all accounts/groups in the system range (strictly below GID/UID\_MIN as
    defined in `/etc/login.defs`) are preserved even though they are not present
    in the configuration. It is possible to use login\_defs/uid\_min and
    login\_defs/gid\_min properties to control the preserved ranges.

- dyn\_user\_group

    all accounts/groups in the system range and in the
    range used for dynamic uid/gid allocation by useradd command, ie. all
    accounts/groups with uid/gid less or equal to GID/UID\_MAX as defined in 
    `/etc/login.defs`, are preserved. The exact list of accounts preserved
    depends on UID/GID\_MAX value. It is possible to use login\_defs/uid\_max and
    login\_defs/gid\_max properties to control the preserved ranges. Not that
    remove\_unknown=true with preserved\_accounts=dyn\_user\_group and UID/GID\_MAX
    set to the highest possible IDs is equivalent to remove\_unknown=false.

- none

    all existing accounts/groups not present in the configuration are
    removed from the system (except root).

Default: dyn\_user\_group

### LIMITATIONS

#### Local users belonging to LDAP groups

When a local user has to belong to a group defined only on LDAP, a
local group with the desired numerical ID is created.

This group has the same name as the user ID. It will be removed on the
next run of the component if `remove_unknown` is set to true. This is
somewhat ugly, but doesn't affect the system behaviour at all, so it
__won't__ be fixed.

#### nsswitch.conf status

The component has been tested with `files` as the primary source on
`/etc/nsswitch.conf` for _group_ and _passwd_. Different settings may
produce strange behaviour. These settings are not controlled by
ncm-accounts but by [ncm-authconfig](https://metacpan.org/pod/ncm-authconfig).

### SEE ALSO

[ncm-authconfig](https://metacpan.org/pod/ncm-authconfig)

Luis Fernando Muñoz Mejías <Luis.Fernando.Munoz.M>
