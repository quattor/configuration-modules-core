object template pamadditions;

function pkg_repl = {return(null);};
include 'components/authconfig/config';
'/software/components/authconfig/dependencies/pre' = null; # remove it to avoid mocking spma

prefix "/software/components/authconfig/pamadditions/system";
"conffile" = "/etc/pam.d/sshd";
"section" = "account";
"lines" = append(dict(
    "order", "first",
    "entry", "required      pam_access.so accessfile=/etc/security/access_sshd.conf",
));
