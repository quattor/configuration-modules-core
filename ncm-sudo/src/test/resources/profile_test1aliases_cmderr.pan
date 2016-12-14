# Simple testing profile for sudo component.
# One incorrect alias defined for users_aliases field. Should fail.
object template profile_test1aliases_cmderr;


"/software/components/sudo/privilege_lines" = list (
    dict ( "user", "ALL",
        "run_as", "ALL",
        "host", "ALL",
        "cmd", "ALL"
        )
    );

"/software/components/sudo/cmd_aliases" = dict (
    "foo", list ("bar")
    );
"/software/components/sudo/active" = true;
"/software/components/sudo/dispatch" = true;
