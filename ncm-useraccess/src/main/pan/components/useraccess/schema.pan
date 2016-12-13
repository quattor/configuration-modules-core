# ${license-info}
# ${developer-info}
# ${author-info}

# Component useraccess
# Author: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>

declaration template components/useraccess/schema;

include 'quattor/schema';

type useraccess_pointer = string with exists ("/software/components/useraccess/roles/"
    + SELF);

# Information needed for Kerberos authentication
type structure_kerberos = {
    "realm" : type_hostname
    "principal" : string    # "User's principal id"
    "instance" ? string    # "User's instance id"
    "host" ? type_hostname    # "The host from which the user can log in"
};

# Types of credentials the component will manage. These will be: "ssh"
# if authorised SSH public keys will be handled, "k4" if Kerberos 4
# will be handled, "k5" if Kerberos 5 will be managed.
type credentialfilestring = string with match(SELF, "^(ssh_keys|kerberos4|kerberos5)$");

# Authoritation information for each user.
type structure_useraccess_auth = {
    # URLs where the public keys that can access to the user can
    # be downloaded
    "ssh_keys_urls" ? type_absoluteURI[]
    # Kerberos 4 credentials for authenticating as an user
    "kerberos4" ? structure_kerberos[]
    # "User's information for authenticating via Kerberos v.5"
    "kerberos5" ? structure_kerberos[]
    # List of ACL-controlled services where the user can access.
    "acls" ? string[]
    # List of roles the user belongs to. References an existing role.
    "roles" ? useraccess_pointer[]
    # List of public keys that can access to the user
    "ssh_keys" ? string[]
    # List of files the component is allowed to modify. Ugly hack
    # fixing some CERN internal problems.
    "managed_credentials" : credentialfilestring[0..3] = list("ssh_keys", "kerberos4", "kerberos5")
};


# Information needed for this component.
# Roles may be nested some day. Anyways, that field doesn't hurt.
type structure_component_useraccess = {
    include structure_component
    "configSerial" ? string
    "users" : structure_useraccess_auth {}
    "roles" ? structure_useraccess_auth {}
    # List of services that will be controlled via ACLs
    "acl_services" ? string[]
};

bind "/software/components/useraccess" = structure_component_useraccess;
