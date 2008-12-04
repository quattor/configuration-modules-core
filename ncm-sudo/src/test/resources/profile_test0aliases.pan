# Simple testing profile for sudo component.
# No aliases defined, just one silly command.
object template profile_test0aliases;
include pro_declaration_types;
include pro_declaration_component_sudo;
include pro_declaration_functions_sudo;

"/software/components/sudo/privilege_lines" = list (
	nlist ( "user",		"ALL",
		"run_as",	"ALL",
		"host",		"ALL",
		"cmd",		"ALL"
		)
	);
"/software/components/sudo/active" = true;
"/software/components/sudo/dispatch" = true;
