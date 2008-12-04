# ${license-info}
# ${developer-info}
# ${author-info}

# Component fsprobe
# Author: Tim Bell <tim.bell@cern.ch>

declaration template components/fsprobe/schema;

include quattor/schema;

# Information needed for Kerberos authentication
type structure_kerberos = {
	"realm"		: type_hostname
	"principal"	: string	# "User's principal id"
	"instance"	? string	# "User's instance id"
	"host"		? type_hostname	# "The host from which the user can log in"
};

# Authoritation information for each user.
type structure_fsprobe_auth = {
	# URLs where the public keys that can access to the user can
	# be downloaded
	"ssh_keys_urls"	? type_absoluteURI[]
	# Kerberos 4 credentials for authenticating as an user
	"kerberos4"	? structure_kerberos[]
	# "User's information for authenticating via Kerberos v.5"
	"kerberos5"	? structure_kerberos[]
	# List of ACL-controlled services where the user can access.
	"acls"		? string[]
	# List of roles the user belongs to. References an existing role.
	"roles"		? string[]
	# List of public keys that can access to the user
	"ssh_keys"	? string[]
};


# Information needed for this component.
# Roles may be nested some day. Anyways, that field doesn't hurt.
type structure_component_fsprobe = {
	include structure_component
	"users"	: structure_fsprobe_auth {}
	"roles"	? structure_fsprobe_auth {}
};

type "/software/components/fsprobe" = structure_component_fsprobe;

