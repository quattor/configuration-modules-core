# Simple testing profile for sudo component.
# One correct alias defined for users_aliases field. Should work OK.
object template profile_test1aliases_cmd;


"/software/components/sudo/privilege_lines" = list (
    dict ( "user", "ALL",
        "run_as", "ALL",
        "host", "ALL",
        "cmd", "ALL"
        )
    );

"/software/components/sudo/cmd_aliases" = dict (
    "FOO", list ("bar")
    );
"/software/components/sudo/active" = true;
"/software/components/sudo/dispatch" = true;
