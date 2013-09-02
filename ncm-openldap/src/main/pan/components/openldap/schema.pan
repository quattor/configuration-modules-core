################################################################################
# This is 'TPL/schema.tpl', a ncm-openldap's file
################################################################################
#
# VERSION:    1.0.0-3, 02/02/10 15:50
# AUTHOR:     Daniel Jouvenot <jouvenot@lal.in2p3.fr>
# MAINTAINER: Guillaume Philippon <philippo@lal.in2p3.fr>
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/openldap/schema;

include { 'quattor/schema' };

function openldap_loglevels_to_long = {
    # converts a list of named loglevels to its numeric value
    # returns undef in case of unknown entry
    # returns (whichever comes first in list)
    #   0 if one of the values is nologging
    #   -1 if one the values is any
    if ( ARGC != 1 || ! is_list(ARGV[0])) {
        error('openldap_loglevel_map requires 1 list argument');
    };
    lvls = ARGV[0];

    default = 'stats';

    the_map = nlist(
        "any", -1, # log all
        "nologging", 0, # (has no official naming) absolutely no logging (none just means very very high loglevel)
        "trace", 1, # trace function calls
        "packets", 2, # debug packet handling
        "args", 4, # heavy trace debugging (function args)
        "conns", 8, # connection management
        "BER", 16, # print out packets sent and received
        "filter", 32, # search filter processing
        "config", 64, # configuration file processing
        "ACL", 128, # access control list processing
        "stats", 256, # connections, LDAP operations, results (recommended)
        "stats2", 512, # stats log entries sent
        "shell", 1024, # print communication with shell backends
        "parse", 2048, # entry parsing
        "sync", 16384, # LDAPSync replication
        "none", 32768, # only messages that get logged whatever log level is set
    );

    if (length(lvls) == 0) {
        lvls = list(default);
    };

    total=0;
    foreach(idx;lvl;lvls) {
        if(!exists(the_map[lvl])) {
            return(undef);
        };
        if(lvl == 'nologging' || lvl == 'any') {
            return(the_map[lvl]);
        };
        total = total | the_map[lvl];
    };
    total;
};

type long_pow2 = long with (SELF==1||SELF==2||SELF==4||SELF==8||
    SELF==16||SELF==32||SELF==64||SELF==128||SELF==256||SELF==512||
    SELF==1024||SELF==2048||SELF==4096||SELF==8192||SELF==16384||
    SELF==32768||SELF==65536||
    error("Only powers of two are accepted"));

# Possible acceptable values
type ldap_hash = string with match(SELF, '\{(S?(SHA|MD5))\}') ||
     error ("Only secure hashes are accepted here: {SSHA, SHA, SMD5, MD5}");

type ldap_sizelimit = {
     "soft" ? long
     "hard" ? long
} with exists(SELF["soft"]) || exists(SELF["hard"]) ||
     error("Either 'soft' or 'hard' limits must be supplied");

type ldap_buffer_size = {
     "listener" ? type_absoluteURI
     "read" ? long
     "write" ? long
} with exists(SELF["read"]) || exists(SELF["write"]) ||
     error("Either 'read' or 'write' limits must be supplied");

type ldap_access_item = {
     "who" ? string
     "access" ? string
     "control" ? string
};

type ldap_access = {
    # what: what = literal string (eg *)
    "what" ? string
    # what attrs turns insto attrs=opt1,opt2
    "attrs" ? string[]


    # by : eg list(list(who,access,control))
    "by" : string[][]
};

type auth_regexp = {
     "match" : string
     "replace" : string
};

type ldap_syntax = string{};

type tls_options = {
     "CipherSuite"          : string = "HIGH"
     "CACertificateFile"    ? string
     "CACertificatePath"    ? string
     "CertificateFile"      ? string
     "CertificateKeyFile"   ? string
     "DHParamFile"          ? string
     "RandFile"             ? string
     "VerifyClient"         ? string with match(SELF, "^(never|allow|try|hard|demand|true)$")
     "CRLCheck"             ? string with match(SELF, "^(none|peer|all)$")
     "CRLFile"              ? string
};


type ldap_global = {
    "access"                    : ldap_access[] = list()
    "allow" ? string[]
    "argsfile" ? string
    "attributeoptions" ? string[]
    # Indexed by attribute name. See RFC4512 for all details.
    "attributetype" ? ldap_syntax{}
    "authid-rewrite" ? string
    "authz-policy" ? string
    "authz-regexp" : auth_regexp[] = list()
    "concurrency" ? long
    "conn_max_pending_auth" ? long
    "defaultsearchbase" ? string
    "disallow" ? string[]
    "ditcontentrule" ? ldap_syntax{}
    "gentlehup" : boolean = false
    "idletimeout" ? long
    "include" ? string
    "ldapsyntax" ? ldap_syntax{}
    # This must be a power of 2
    "listener-threads" ? long_pow2
    "localSSF" : long = 71
    "logfile" ? string
    "loglevel" ? long
    "moduleload"                ? string[]
    "modulepath" ? string
    "objectclass" ? ldap_syntax{}
    "password-hash" : ldap_hash = "{SSHA}"
    "password-crypt-salt-format" ? string
    "pidfile" ? string
    "referral" ? type_URI
    "require" ? string[]
    "reverse-lookup" : boolean = false
    "rootDSE" ? string
    "sasl-auxprops" ? string
    "sasl-host" ? type_fqdn
    "sasl-ream" ? string
    "sasl-secprops" ? string
    "schemadn" ? string
    "security" ? string
    "serverID" ? long(0..4095)
    "sizelimit" ? ldap_sizelimit
    "sockbuf_max_incoming" ? long
    "sockbuf_max_incoming_auth" ? long
    "sortvals" ? string[]
    "tcp-buffer" ? ldap_buffer_size
    "threads" : long(2..) = 16
    "tls"                       ? tls_options
    "timelimit" ? long
    "tool-threads" : long = 1
    "writetimeout"              ? long
};


type ldap_database_string = string with
     match(SELF, "^(bdb|config|dnssrv|hdb|ldap|ldif|meta|" +
	             "monitor|null|passwd|perl|relay|shell|sql)$") ||
     error("Unknown LDAP database type. " +
	       "Check sladpd.conf man page");

type ldap_ops = string with
     match(SELF, '^(add|bind|compare|delete|modify|rename|search|read|write|'+
	             '(extended=\w+)|rename)$');

type ldap_replica_retries = {
     "interval" : string
     "retries" : long
};

type ldap_replica_cfg = {
     "rid" : long(0..999)
     "provider" : type_absoluteURI
     "searchbase" : string
     "type" ? string with match(SELF, "^(refreshOnly|refreshAndPersist)$")
     "interval" ? string
     "retry" ? ldap_replica_retries[]
     "scope" ? string with match(SELF, "^(sub|one|base|subord)$")
     "attrs" ? string[]
     "attrsonly" ? boolean
     "sizelimit" ? long
     "timelimit" ? long
     "schemachecking" : boolean = false
     "network-timeout" ? long
     "timeout" ? long
     "bindmethod" ? string with match(SELF, "^(simple|sasl)$")
     "binddn" ? string
     "saslmech" ? string
     "authcid" ? string
     "authzid" ? string
     "credentials" ? string
     "realm" ? string
     "secprops" ? string
     "keepalive" ? string
     "starttls" ? string with match(SELF, "^(yes|critical)$")
     "tls_cert" ? string
     "tls_key" ? string
     "tls_cacert" ? string
     "tls_cacertdir" ? string
     "tls_reqcert" ? string with match(SELF, "^(never|allow|try|demand)$")
     "tls_ciphersuite" ? string
     "tls_crlcheck" ? string with match(SELF, "^(none|peer|all)$")
     "suffixmassage" ? string
     "logbase" ? string
     "logfilter" ? string
     "syncdata" ? string with match(SELF, "^(default|accesslog|changelog)$")
     "filter" ? string
};


# overlay Replication (SyncProvider)
type ldap_overlay_syncprov = {
    # use a list for checkpoint: first val is ops, second value is minutes
    "checkpoint"            ? long[] with (length(SELF) == 2)
    "sessionlog"            ? long
    "nopresent"             ? boolean
    "reloadhint"            ? boolean
};

type type_ldap_overlay = {
     "syncprov"     ? ldap_overlay_syncprov
};

type type_db_config = {
    # set_cachesize 0 268435456 1 (one 0.25 GB cache)
    "cachesize"     ? long[] with (length(SELF) == 3) # = list(0,268435456,1)
    # set_lg_regionmax 262144
    "lg_regionmax"  ? long = 262144
    # set_lg_bsize 2097152
    "lg_bsize"      ? long = 2097152
    # set_lg_max 10485760
    "lg_max"        ? long = 10485760
};

type ldap_database_limits = {
     "size" ? ldap_sizelimit
     "time" ? ldap_sizelimit
};

type ldap_monitoring = {
    "default"   ? boolean = true
};

type ldap_database = {
     "class" : ldap_database_string
     "add_content_acl" : boolean = false
     "db_config"        ? type_db_config
     "directory"        ? string
     "extra_attrs" ? string[]
     # eg list(list(list("entryCSN","entryUUID"),list("eq")))
     "index"            ? string[][][]
     "hidden" : boolean = false
     "lastmod" : boolean = true
     "limits" ? ldap_database_limits{}
     "maxderefdepth" : long = 15
     "mirrormode" ? boolean # don't set it (not setting it is not equal to false or true)
     "monitoring" ? boolean
     "overlay"          ? type_ldap_overlay
     "readonly" ? boolean = false
     "restrict" ? ldap_ops[]
     "rootdn" ? string
     "rootpw" ? string
     "suffix" ? string
     "subordinate" ? boolean
     "sync_use_subentry" ? boolean
     "syncrepl" ? ldap_replica_cfg
     "updatedn" ? string
     "updateref" ? type_absoluteURI
     "backend_specific" ? string[]{}
};

type component_openldap = {
	include structure_component
	'conf_file'		: string = "/etc/openldap/slapd.conf"
	'include_schema'	: string[]
	'loglevel' 		? long(0..)
	'pidfile' 		? string
	'argsfile' 		? string
	'database'		: string
	'suffix'		: string
	'rootdn'		: string
	'rootpw'		: string
	'directory'		: string
	'index'			? string[]
	'global'   ? ldap_global
	'backends'	? ldap_database[]
	'databases'	? ldap_database[]
	'monitoring' ? ldap_monitoring
	# move the /etc/openldap/slapd.d dir (this  
	#  configuration method takes preferences over the  
	#  slapd.conf file, but it is not supported by the component)
	'move_slapdd' ? boolean = true  
};

bind '/software/components/openldap' = component_openldap;

