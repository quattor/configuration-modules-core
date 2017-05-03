# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

@documentation{
sudo template sets the sudoers file.
oneadmin user should be able to restart libvirt services
and set virsh secret (Ceph) in each host.
}

unique template components/${project.artifactId}/sudo;

include 'components/sudo/config';

"/software/components/sudo/privilege_lines" = {
    sudolist = list(
        "/sbin/service libvirtd restart",
        "/sbin/service libvirt-guests restart",
        '/usr/bin/virsh secret-set-value *',
        '/usr/bin/virsh secret-define *',
        '/usr/sbin/iptables',
        '/usr/sbin/ebtables',
        '/usr/bin/ovs-vsctl',
        '/usr/bin/ovs-ofctl',
        '/usr/sbin/ipset',
        '/usr/sbin/ip',
        '/usr/sbin/brctl',
    );
    foreach (i; cmd; sudolist){
        nl = dict("host", "ALL",
            "options", "NOPASSWD:",
            "run_as", "ALL",
            "user", "oneadmin");
        nl["cmd"] = cmd;
        append(nl);
    };
    SELF;
};
