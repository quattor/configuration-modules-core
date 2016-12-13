# Test profile for the useraccess component.
# All fields have two values.
# Should compile fine.
object template  profile_test2fieldseach;

include pro_declaration_component_useraccess;
include pro_declaration_functions_useraccess;


"/software/components/useraccess/users/foo" = dict(
    "ssh_keys_urls", list(
        "http://www.cern.ch/foo",
        "http://www.uam.es/bar",
    ),
    "kerberos4", list(
        dict(
            "realm", "cern.ch",
            "principal", "bar",
        ),
        dict(
            "realm", "uam.es",
            "principal", "me",
            "instance", "whocares",
        ),
    ),
    "kerberos5", list(
        dict(
            "realm", "cern.ch",
            "principal", "bar",
            "instance", "dontknow",
        ),
        dict(
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
