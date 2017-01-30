# Simple testing profile for sudo component.
# No aliases defined, just one silly command.
object template profile_test0aliases;

"/software/components/sudo/privilege_lines" = list (
    dict ( "user", "ALL",
        "run_as", "ALL",
        "host", "ALL",
        "cmd", "ALL"
        )
    );
"/software/components/sudo/active" = true;
"/software/components/sudo/dispatch" = true;
