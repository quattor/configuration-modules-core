# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/krb5clt/schema;

include {'quattor/schema'};

type component_krb5clt = {
        include structure_component

        # top-level comment, triggers diff behaviour from scripts
        "cern_use_ad_kdc"         ? boolean
        # libdefaults
	"default_realm"		? string
	"ticket_lifetime"	? string
	"renew_lifetime"	? string
	"forwardable"		? boolean
	"proxiable"		? boolean
        "default_tkt_enctypes"  ? string
        "allow_weak_crypto"     ? string with match (SELF, 'true|false')
	# realms
	"cern_kpasswd_server"	? string
	"cern_admin_server"	? string
	"cern_kdc_list"		? string[]
	"cern_kdc_weights"	? double[]
        # other PAM appdefault options, valid for 2.2.8
        "pam_banner"		? string
        "pam_ccache_dir"	? string
        "pam_existing_ticket"	? string with match (SELF, 'true|false')
        "pam_ignore_afs"	? string with match (SELF, 'true|false')
        "pam_ignore_unknown_principals"		? string with match (SELF, 'true|false')
        "pam_initial_prompt"	? string with match (SELF, 'true|false')
        "pam_keytab"		? string
        "pam_krb4_convert"	? string with match (SELF, 'true|false')
        "pam_krb4_convert_524"	? string with match (SELF, 'true|false')
        "pam_krb4_use_as_req"	? string with match (SELF, 'true|false')
        "pam_mappings"		? string
        "pam_minimum_uid"	? long
        "pam_no_user_check"	? string with match (SELF, 'true|false')
        "pam_realm"		? string
        "pam_renew_lifetime"	? string
        "pam_ticket_lifetime"	? string
        "pam_tokens"		? string with match (SELF, 'true|false')
        "pam_use_shmem"		? string
        "pam_validate"		? string
        "pam_afs_cells"		? string
        # The next options require CERN patches to pam_krb5
        "pam_cern_nullafs"	? string with match (SELF, 'true|false')
        "pam_cern_prefer2b"	? string with match (SELF, 'true|false')
        # use with AD
        "pkinit_pool"           ? string
        "pkinit_anchors"        ? string

        # the following optional entries are for compatibility
        # with the previous version, and can eventually be removed
	"login"		? nlist
	"logging"	? nlist
	"libdefaults"	? nlist
	"realms"	? nlist
	"domain_realm"	? nlist
	"appdefaults"	? nlist
	"capaths"	? nlist
	"kdc"		? nlist
	"kadmin"	? nlist

        #########################################
	# were also in previous structure, eventually remove..
	"libdefaults/default_realm"	? string
	"libdefaults/default_etypes"	? string
	"libdefaults/default_etypes_des" ? string
	"libdefaults/ticket_lifetime"   ? long
	"libdefaults/renew_lifetime"    ? long
	"realms/kdc"			? list
	"realms/admin_server"		? string
	"realms/kpasswd_server"		? string
	"realms/default_domain"		? string
};

bind "/software/components/krb5clt" = component_krb5clt;

