# Test profile for the useraccess component.
# All fields have two values.
# Should compile fine.
object template  profile_test2fieldseach;

include pro_declaration_component_useraccess;
include pro_declaration_functions_useraccess;


"/software/components/useraccess/users/foo" = nlist(
    "ssh_keys_urls", list(
        "http://www.cern.ch/foo",
        "http://www.uam.es/bar",
    ),
    "kerberos4", list(
        nlist(
            "realm", "cern.ch",
            "principal", "bar",
        ),
        nlist(
            "realm", "uam.es",
            "principal", "me",
            "instance", "whocares",
        ),
    ),
    "kerberos5", list(
        nlist(
            "realm", "cern.ch",
            "principal", "bar",
            "instance", "dontknow",
        ),
        nlist(
            "realm", "uam.es",
            "principal", "shutup",
        ),
    ),
    "acls", list(
        "inetd",
        "login",
    ),
);
"/software/components/useraccess/active" = true;
"/software/components/useraccess/dispatch" = true;
