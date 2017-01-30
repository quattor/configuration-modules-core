# Simple testing profile for sudo component.
# One correct alias defined for users_aliases field and a valid entry for
# command options. Should work OK.
# One valid entry without hosts, users or run_as as a general_option.
object template profile_test_general_options_valid;
include pro_declaration_types;
include pro_declaration_component_sudo;
include pro_declaration_functions_sudo;

"/software/components/sudo/privilege_lines" = list (
    dict ( "user", "mejias",
        "run_as", "munoz",
        "host", "localhost",
        "cmd", "/bin/ls",
        "options", "NOPASSWD"
        )
    );

"/software/components/sudo/user_aliases" = dict (
    "FOO", list ("bar")
    );
"/software/components/sudo/active" = true;
"/software/components/sudo/dispatch" = true;

"/software/components/sudo/general_options/" = list (
    dict (
        "options", dict ("insults", true)
        )
    );
