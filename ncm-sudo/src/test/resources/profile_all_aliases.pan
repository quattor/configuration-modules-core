# Simple testing profile for sudo component.
# One correct alias defined for users_aliases field. Should work OK.
object template profile_all_aliases;

prefix "/software/components/sudo";

"user_aliases" = nlist (
	"USER", list ("u")
	);
"cmd_aliases" = nlist("CMD", list("c"));
"run_as_aliases" = nlist("RUN", list("r"));
"host_aliases" = nlist("HOST", list("h", "h2"));
