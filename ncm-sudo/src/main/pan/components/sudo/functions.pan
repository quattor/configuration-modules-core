# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/sudo/functions;

include 'quattor/schema';
include 'components/sudo/schema';

# Checks all the alias names in an alias list are valid.
# It aborts the compilation if there is an invalid alias name.
# It receives as arguments the whole component_sudo structure and
# the name of the alias list.
# TO BE CALLED ONLY FROM is_structure_sudo_component!!
function check_aliases_list = {
    if (!exists(ARGV[0][ARGV[1]])) {
        return (true);
    };
    ls = ARGV[0][ARGV[1]];
    ok = first (ls, aliasname, aliascnt);
    while (ok) {
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
        ok = next(ls, aliasname, aliascnt);
    };
};


# Checks the validity of the default options.
# This means that AT MOST, one of "user", "run_as" or "host" may be
# specified on each entry.
function check_default_options_list = {

    if (!exists (ARGV[0][ARGV[1]])) {
        return (true);
    };
    ls = ARGV[0][ARGV[1]];
    ok = first (ls, opt, v);
    while (ok) {
        if ((exists (v["user"]) && (exists (v["run_as"]) ||
            exists (v["host"]))) ||
            (exists (v["run_as"]) && exists (v["host"]))) {
            error ("Only one of user, run_as or host may be " +
                "specified for default options");
        };
        ok = next (ls, opt, v);
    };
};

# Sanity checks for SUDO component.
# A privilege line with any field in capitals
# will be checked against aliases for its existence.

function is_structure_sudo_component = {

    st=value (ARGV[0]);
    check_aliases_list (st, "user_aliases");
    check_aliases_list (st, "run_as_aliases", );
    check_aliases_list (st, "cmd_aliases");
    check_default_options_list (st, "general_options");
    return (true);
};


valid "/software/components/sudo" = is_structure_sudo_component (
    "/software/components/sudo");
