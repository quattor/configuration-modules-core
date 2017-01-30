# Simple testing profile for sudo component.
# One correct alias defined for users_aliases field. Should work OK.
object template profile_all_aliases;

prefix "/software/components/sudo";

"user_aliases" = dict (
    "USER", list ("u")
    );
"cmd_aliases" = dict("CMD", list("c"));
"run_as_aliases" = dict("RUN", list("r"));
"host_aliases" = dict("HOST", list("h", "h2"));
