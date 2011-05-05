# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/postgresql
#
#
#
#
############################################################


declaration template components/postgresql/schema;

include quattor/schema;

type pg_db = {
	"user" ? string
	"installfile" ? string
	"sql_user" ? string
	"lang" ? string
	"langfile" ? string
};

type structure_pgsql_comp_config = {
	"debug_print" ? long 
};

type component_pgsql = {
    include structure_component
	include structure_component_dependency

	"pg_script_name" ? string
	"pg_dir" ? string
	"pg_port" ? string
	"postgresql_conf" ? string
	"pg_hba" ? string
	"roles" ? string{}
	"databases" ? pg_db{}
	"commands" ? string{}
	"config" ? structure_pgsql_comp_config
	"pg_version" ? string
	"pg_engine" ? string
};

type "/software/components/postgresql" = component_pgsql;

