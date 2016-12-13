# Test profile for the useraccess component.
# All fields have one value.
# Should compile fine.
object template  profile_test1fieldeach;

include pro_declaration_component_useraccess;
include pro_declaration_functions_useraccess;


"/software/components/useraccess/users/foo" = dict(
    "ssh_keys_urls", list(
        "http://www.cern.ch/foo",
    ),
    "kerberos4", list(
        dict(
            "realm", "cern.ch",
            "principal", "bar",
        ),
    ),
    "kerberos5", list(
        dict(
            "realm", "cern.ch",
            "principal", "bar",
            "instance", "dontknow",
        ),
    ),
    "acls", list(
        "mail",
    ),
);
"/software/components/useraccess/active" = true;
"/software/components/useraccess/dispatch" = true;
