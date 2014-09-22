# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


unique template components/${project.artifactId}/sudo;

include 'components/sudo/config';


"/software/components/sudo/privilege_lines" = {
     sudolist = list(
         "/sbin/service libvirtd restart",
         "/sbin/service libvirt-guests restart",
         "/usr/bin/virsh secret-set-value",
         "/usr/bin/virsh secret-define"
     );
     foreach (i; cmd; sudolist){
         nl = nlist("host", "ALL",
                    "options", "NOPASSWD:",
                    "run_as", "ALL",
                    "user", "oneadmin");
         nl["cmd"] = cmd;
         append(nl);
     };
     SELF;
};
