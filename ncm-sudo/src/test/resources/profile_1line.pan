object template profile_1line;

prefix "/software/components/sudo";

"privilege_lines/0" = dict("user", "u",
    "run_as", "r",
    "host", "h",
    "cmd", "c",
    "options", "opts");

"privilege_lines/1" = dict("user", "u",
    "run_as", "r",
    "host", "h",
    "cmd", "c");
