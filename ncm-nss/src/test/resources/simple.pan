object template simple;

# mock pkg_repl
function pkg_repl = { null; };
include 'components/nss/config';
"/software/components/nss/dependencies/pre" = null;

prefix "/software/components/nss";
"databases/passwd" = list("files", "ldap");
"build/ldap/script" = "/usr/sbin/buildldap -d <DB>";
"build/ldap/active" = true;
"build/db/script" = "/usr/sbin/builddb";
# active has a de-facto value of false in the code
#"build/db/active" = false;


