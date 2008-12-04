# Simple testing profile for sudo component.
# One correct alias defined for users_aliases field. Should work OK.
object template profile_test1aliases;
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

"/software/components/sudo/user_aliases" = nlist (
	"FOO", list ("bar")
	);
"/software/components/sudo/active" = true;
"/software/components/sudo/dispatch" = true;
