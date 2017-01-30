# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


unique template components/${project.artifactId}/ceph-user;

include 'components/accounts/config';

# do not change uids of existing cluster
variable CEPH_OLD_UID ?= true; # set to false for new clusters, especially infernalis and above
variable CEPH_USER_ID = {
    if (CEPH_OLD_UID) {
        deprecated(0, 'ceph user should get a new uid. set final CEPH_OLD_UID = false');
        111;
    } else {
        167;
    };
};

prefix '/software/components/accounts';

"groups/ceph" = dict("gid", CEPH_USER_ID);

"users/ceph" = dict(
    "uid", CEPH_USER_ID,
    "groups", list("ceph"),
    "comment","ceph",
    "shell", "/bin/sh",
    "homeDir", "/home/ceph",
    "createHome", true,
);

'kept_users/ceph' = '';
'kept_groups/ceph' = '';
