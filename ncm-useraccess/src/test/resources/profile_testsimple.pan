############################################################
#
# object template profile_testsimple
#
# Test template for ncm-useraccess.
# Tests one user with all valid fields and no roles.
# Should compile OK. Check the files in the testing node.
############################################################


object template profile_testsimple;

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

