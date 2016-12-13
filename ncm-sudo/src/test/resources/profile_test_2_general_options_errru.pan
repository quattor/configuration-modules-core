# Simple testing profile for sudo component.
# One correct alias defined for users_aliases field and a valid entry for
# command options. Should not compile
# One valid entry and one invalid entry with a host and an
# user as general_options.
object template profile_test_2_general_options_invalidru;
include pro_declaration_types;
include pro_declaration_component_sudo;
include pro_declaration_functions_sudo;

"/software/components/sudo/privilege_lines" = list(
    dict(
        "user", "mejias",
        "run_as", "munoz",
        "host", "localhost",
        "cmd", "/bin/ls",
        "options", "NOPASSWD",
    )
);

"/software/components/sudo/user_aliases" = dict(
    "FOO", list(
        "bar",
    ),
);
"/software/components/sudo/active" = true;
"/software/components/sudo/dispatch" = true;

"/software/components/sudo/general_options/" = list(
    dict(
        "user", "mejias",
        "options", dict(
            "insults", true,
        ),
    ),
    dict(
        "user", "munoz",
        "host", "192.168.0.1",
        "options", dict(
            "insults", true,
        ),
    ),
);
