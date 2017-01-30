# Test profile for the useraccess component.
# All fields are empty.
# Should compile fine.
object template profile_testempty;

include pro_declaration_component_useraccess;
include pro_declaration_functions_useraccess;

"/software/components/useraccess/users/foo" = dict(
    "ssh_keys_urls", list (),
    "kerberos4", list (),
    "kerberos5", list (),
    "acls", list (),
);
"/software/components/useraccess/active" = true;
"/software/components/useraccess/dispatch" = true;
