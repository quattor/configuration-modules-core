# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/pam/schema;

include { 'quattor/schema' };

type component_pam_options = extensible {
};

type component_listfile_acl = {
	"filename" : string
	"items"    : string[]
};

type component_pam_module_stack = {
	"control" : string with match(SELF, "requisite|required|optional|sufficient")
	"module"  : string
	"options" ? component_pam_options
	"allow"   ? component_listfile_acl
	"deny"    ? component_listfile_acl
};

type component_pam_service_type = {
	"auth"     ? component_pam_module_stack[]
	"account"  ? component_pam_module_stack[]
	"password" ? component_pam_module_stack[]
	"session"  ? component_pam_module_stack[]
	"mode"     ? string with match(SELF, "0[0-7][0-7][0-7]")
};

type component_pam_module = {
	"path" ? string
};

# see pam_access(8)

type component_pam_access_entry = {
	"permission" : string with match(SELF, "^[-+]$")
	"users"      : string
        "origins"    : string
};

type component_pam_access = {
	"filename" : string
	"acl"      : component_pam_access_entry[]
	"lastacl"  : component_pam_access_entry
	"allowpos" : boolean
	"allowneg" : boolean
};

type component_pam_entry = {
	include       structure_component
	"modules"   ? component_pam_module{}
	"services"  ? component_pam_service_type{}
	"directory" ? string
	"acldir"    ? string
	"access"    ? component_pam_access{}
};

bind "/software/components/pam" = component_pam_entry;
