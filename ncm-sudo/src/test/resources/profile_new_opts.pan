object template profile_new_opts;

prefix "/software/components/sudo";

"privilege_lines/0" = nlist("user", "u",
    "run_as", "r",
    "host", "h",
    "cmd", "c",
    "options", "NOPASSWD:EXEC:");
