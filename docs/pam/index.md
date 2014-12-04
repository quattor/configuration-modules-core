---
layout: documentation
title: pam
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

NCM::pam - NCM pam configuration component

### SYNOPSIS

    ### declare what pam modules are available.
    "/software/components/pam/modules" = npush("krb5", 
	nlist("path", "/lib/security/$ISA/pam_krb5.so"));
    "/software/components/pam/modules" = npush("cracklib", 
	nlist("path", "/lib/security/$ISA/pam_cracklib.so"));

    ### setup a service
    "/software/components/pam/services" = pam_add(
       "sshd", "auth", "required", "env");
    "/software/components/pam/services" = pam_add_stack(
       "sshd", "password", "required", "system-auth");
    "/software/components/pam/services" = pam_add(
       "sshd", "session", "required", "limits");
    "/software/components/pam/services" = pam_add(
       "sshd", "session", "required", "unix");

- Configure()

    Returns
    error in case of failure.

- Unconfigure()

    not available.

### RESOURCES

- `/software/components/pam/active` : boolean

    activates/deactivates the component.

- `/software/components/pam/modules` : nlist

    contains the list of supported PAM modules. For each module, the value
    should be an nlist containing that path for that named module. The
    name can be anything you want. When describing the PAM configuration
    for services, the names provided here are the only acceptable names
    of modules, so it is the responsibility of the operating system
    templates to define the available modules.

- `/software/components/pam/services`: nlist

    contains an nlist of services that are being controlled by this
    component. Any service controlled will have it's PAM configuration
    completely replaced by this module. Stacked or included PAM
    configurations (i.e. configurations that use pam\_stack.so or the
    include directive) must ensure that the service being stacked is
    already defined.

    For each service, the value will be an nlist keyed off the module type
    (auth, account, session, password). The value for each module type is
    an ordered list of mappings. Each mapping is an nlist that is keyed
    off the action (i.e. required, optional, etc).  Only a single action
    is expected in each nlist.

    The nlist may contain the key "predefined" with a boolean value. If
    set to true, then this service name is expected to be on the system,
    but will not be actively managed by this component.  For example, the
    "system-auth" service can be listed with this value, which will allow
    other services to stack/include that service configuration, without
    requiring that this component take over management of the
    "system-auth" component. __This functionality is not implemented at
    this time__.

    PAM config files for services which are not specified within this list
    will not be touched.

- `/software/components/pam/acls`: nlist

    Every ACL being managed by this component must be given a name
    and placed into this nlist. The value of the ACL is itself an nlist containing:

    - items

        a list of items to place into the acl

    - file

        optionally the filename for the ACL. If this is not provided, then a filename
        will be generated based on `/software/components/pam/acldir`, the name of
        the ACL and the sense in which it is being used.

- `/software/components/pam/directory`: string

    The directory where the config files will be placed, defaulting to `/etc/pam.d`

- `/software/components/pam/acldir`: string

    The directory where the ACL files will be placed, defaulting to `/etc/pam.acls`

### FUNCTIONS

The component provides the following functions to assist in creating configurations:

- pam\_add(SERVICE, TYPE, CONTROL, MODULE, OPTIONS?)

    This function should be applied to
    "/software/components/pam/services". A mapping is appended to the
    appropriate point in the configuration tree. SERVICE refers to the
    service name being configured (e.g. "sshd"). TYPE refers to the module
    type (e.g. "auth"). CONTROL refers to the action that is taken when
    the PAM system encounters this mapping (e.g. "required"). MODULE is
    the name of a module listed within
    "/software/components/pam/modules". OPTIONS is an optional argument;
    if supplied it should be an nlist containing additional information
    for the PAM module.

- pam\_add\_stack(SERVICE, TYPE, CONTROL, STACKEDSERVICE)

    This function is applied to `/software/components/pam/services`

    A mapping is appended to the appropriate point in the configuration
    tree. SERVICE refers to the service being configured (e.g. "sshd").
    TYPE refers to the module type (e.g. "auth"). CONTROL refers to the
    action that is taken when the PAM system encounters this mapping
    (e.g. "required"). STACKEDSERVICE is the name of the service that
    should be stacked (e.g. "system-auth").

- pam\_add\_listfile\_acl(SERVICE, TYPE, CONTROL, SENSE, ITEMTYPE, ITEMS, ONERR?)

    This function should be applied to `/software/components/pam/services.`

- pam\_add\_access\_file(KEY, FILENAME, ALLOWPOS, ALLOWNEG)

    This function should be applied to "/software/components/pam/access". 
    See pam\_access(8) for more details. Example:

        "/software/components/pam/access" = pam_add_access_file("access",
           "/etc/security/access.conf", true, false);

- pam\_add\_access\_lastacl(KEY, PERMISSION, USERS, ORIGINS)

    This function should be applied to "/software/components/pam/access"
    and sets the value of the last ACL in the access file. Typically this is used to ensure last entry in the ACL is: "-:ALL:ALL"

- pam\_add\_access\_acl(KEY, PERMISSION, USERS, ORIGINS)

    This function is used to implement the pam\_add\_access\_netgroup and
    pam\_add\_access\_user functions.

- pam\_add\_access\_netgroup(KEY, NETGROUP)

    This function should be applied to "/software/components/pam/access".
    It adds a netgroup the access file using the correct syntax. Example:

        "/software/components/pam/access" = pam_add_access_netgroup(
           "access", "mygroup");

- pam\_add\_access\_user(KEY, USER)

    This function should be applied to "/software/components/pam/access".
    It adds a user to the access file.

### FILES MODIFIED

The component pam modifies files within the `/etc/pam.d` directory the `/etc/pam.acls` directory.

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

### EXAMPLES

"/software/components/pam/active" = true;

### BUGS

Cannot stack or include services that are not managed by this module.

### SEE ALSO

ncm-ncd(1)
