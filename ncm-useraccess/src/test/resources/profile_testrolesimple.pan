############################################################
#
# object template profile_testrolesimple
#
# Test template for ncm-useraccess.
# Tests two users:
# root has all his settings directly in the profile.
# mejias gets its settings from a role.
# base role contains the same settings as user root.
# Should compile OK. Check the files in the testing node.
# mejias and root should get the exact same configuration.
############################################################


object template profile_testrolesimple;

"/system/network/hostname"                  = "chii";
variable HOSTNAME = value ( "/system/network/hostname");
# Base configuration for every test.
include clusters/testing/testbase;

include components/useraccess/config;


"/software/components/useraccess/users/root" = dict (
    "kerberos4", list (
        dict (
            "realm", "CERN.CH",
            "principal", "munoz",
            )
        ),
    "kerberos5", list (
        dict (
            "realm", "CERN.CH",
            "principal", "munoz"
            )
        ),
    "ssh_keys_urls", list("http://uraha/keys/mejias.key"),
    "ssh_keys", list ("ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA5Px4X4NN/U/0kGwlV8GrPeQK6T9jo7BfpTGLTAshleb/NbyhFJXLiGf+hFsWtXSxXjiDFZPEAXNQc1+JKp6dmURIp+o+BPhqz49GgM+2qZ+OqxxPdxhtqhTIUclKNjDZxzRNuTBCLGM+/K4Ws5PaVkpwvefU3LcjdV2Y3ThiOJ8= root@uraha.air.tv")
    );

"/software/components/useraccess/roles/base" = dict (
    "kerberos4", list (
        dict (
            "realm", "CERN.CH",
            "principal", "munoz",
            )
        ),
    "kerberos5", list (
        dict (
            "realm", "CERN.CH",
            "principal", "munoz"
            )
        ),
    "ssh_keys_urls", list("http://uraha/keys/mejias.key"),
    "ssh_keys", list ("ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA5Px4X4NN/U/0kGwlV8GrPeQK6T9jo7BfpTGLTAshleb/NbyhFJXLiGf+hFsWtXSxXjiDFZPEAXNQc1+JKp6dmURIp+o+BPhqz49GgM+2qZ+OqxxPdxhtqhTIUclKNjDZxzRNuTBCLGM+/K4Ws5PaVkpwvefU3LcjdV2Y3ThiOJ8= root@uraha.air.tv")
    );

    "/software/components/useraccess/users/mejias/roles" = list ("base");
