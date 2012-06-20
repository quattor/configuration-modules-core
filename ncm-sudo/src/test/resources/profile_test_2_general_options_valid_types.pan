# Simple testing profile for sudo component.
# One correct alias defined for users_aliases field and a valid entry for
# command options. Should work OK.
# Two valid entries with a host and an user as general_options.
# Tests options of boolean, integer and string types
object template profile_test_2_general_options_valid_types;
include pro_declaration_types;
include pro_declaration_component_sudo;
include pro_declaration_functions_sudo;

"/software/components/sudo/privilege_lines" = list (
	nlist ( "user",		"mejias",
		"run_as",	"munoz",
		"host",		"localhost",
		"cmd",		"/bin/ls",
		"options",	"NOPASSWD"
		)
	);

"/software/components/sudo/user_aliases" = nlist (
	"FOO", list ("bar")
	);
"/software/components/sudo/active" = true;
"/software/components/sudo/dispatch" = true;

"/software/components/sudo/general_options/" = list (
	nlist ("user", "mejias",
	       "options", nlist ("insults", true,
		      "mailerpath", "/sbin/sendmail")
		),
	nlist (
		"host", "192.168.0.1",
		"options", nlist ("insults", true,
		       "timestamp_timeout", 15)
		)
	);
