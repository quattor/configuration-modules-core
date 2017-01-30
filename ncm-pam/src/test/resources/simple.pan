object template simple;

# constructed from the examples in pam.pod

prefix "/software/components/pam";

"acldir" = "/etc/pam.acls";
"directory" = "/etc/pam.d";

# declare what pam modules are available.
"modules/env/path" = "/lib/security/$ISA/pam_env.so";
"modules/limits/path" = "/lib/security/$ISA/pam_limits.so";

# configure /etc/pam.d/sshd
"services/sshd/auth" = append(dict("control", "required", "module", "env"));
"services/sshd/password" = append(dict("control", "required",
                      "module", "include",
                      "options", dict("service", "/etc/pam.d/system-auth")));

"services/sshd/session" = append(dict("control", "required",
                                       "module", "limits"));

# declare an ACL
"access/access/acl/0/origins" = "ALL";
"access/access/acl/0/permission" = "+";
"access/access/acl/0/users" = "@netgroup";
"access/access/acl/1/origins" = "ALL";
"access/access/acl/1/permission" = "+";
"access/access/acl/1/users" = "user";
"access/access/allowneg" = false;
"access/access/allowpos" = true;
"access/access/filename" = "/etc/security/access.conf";
"access/access/lastacl/origins" = "ALL";
"access/access/lastacl/permission" = "-";
"access/access/lastacl/users" = "ALL";

