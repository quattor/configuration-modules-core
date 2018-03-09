# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/sudo/validation;

@{Checks all the alias names in an alias list are valid
  (must match the regexp ^[A-Z][A-Z0-9_]*$ i.e.
  start with letter, only letters, numbers and underscores allowed, and all capitals).
  It aborts the compilation if there is an invalid alias name.
  It receives as arguments the whole component_sudo structure and
  the name of the alias list.};
function sudo_check_aliases_list = {
    if (exists(ARGV[0][ARGV[1]])) {
        foreach(idx; aliasname; ARGV[0][ARGV[1]]) {
            if (!match (aliasname, "^[A-Z][A-Z0-9_]*$")) error(
                "Wrong alias name: " + aliasname +
                "\nAn alias name must be made of " +
                "capitals, numbers and underscores " +
                "and start with a capital. " +
                "Only ASCII characters are allowed."
            );
            if (aliasname == "ALL") {
                error("ALL alias is a reserved keyword");
            };
        };
    };
    true;
};


@{Checks the validity of the default options.
  This means that AT MOST one of "user", "run_as" or "host" may be
  specified on each entry.}
function sudo_check_default_options_list = {
    if (exists(ARGV[0][ARGV[1]])) {
        foreach(idx; v; ARGV[0][ARGV[1]]) {
            if ((exists (v["user"]) && (exists (v["run_as"]) ||
                exists (v["host"]))) ||
                (exists (v["run_as"]) && exists (v["host"]))) {
                error ("Only one of user, run_as or host may be " +
                        "specified for default options");
            };
        };
    };
    true;
};

@{Sanity checks for SUDO component.
  A privilege line with any field in capitals
  will be checked against aliases for its existence.}
function sudo_is_structure_component = {
    st = value(ARGV[0]);
    sudo_check_aliases_list(st, "user_aliases");
    sudo_check_aliases_list(st, "run_as_aliases");
    sudo_check_aliases_list(st, "cmd_aliases");
    sudo_check_default_options_list(st, "general_options");
    true;
};

valid "/software/components/sudo" = sudo_is_structure_component("/software/components/sudo");
