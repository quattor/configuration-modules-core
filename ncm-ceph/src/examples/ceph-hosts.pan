unique template site/ceph;

final variable FILESYSTEM_LAYOUT_CONFIG_SITE = 'site/filesystems/ceph';
final variable KERNEL_VERSION_NUM = '2.6.32-431.5.1.el6.ug';

include 'machine-types/base';
include 'components/fstab/config';
include 'components/filesystems/config';
include 'components/ceph/config';

prefix "/software/packages";
"{xfsprogs}" = nlist();
"{xfsdump}" = nlist();

variable OS_REPOSITORY_LIST = append('ceph-deploy');
variable OS_REPOSITORY_LIST = append('ceph-extras-noarch');
variable OS_REPOSITORY_LIST = append('ceph-extras');
variable OS_REPOSITORY_LIST = append('ceph-noarch');
variable OS_REPOSITORY_LIST = append('ceph');

## add ceph user

include 'components/accounts/config';
include 'components/sudo/config';
include 'components/ceph/ceph-user';
include 'components/ceph/sudo';


final variable CEPH_DEPLOY_PUBKEYS = list(
"ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAy4Qtc2Re7IeO1qcDW0shTuYJ5lKVkRmksj7TrWAy8gyB1CfmcCJA/sIJLYpvOephOu7LewhvCisjUpfsh6wj5PHeVl7q3AkQRe1JUHq5tedli4qCT3jv0FStCNSAUrHFf2oADJhKStTuiIPd+S2CGaWEAMj6aU+IE55yss7Y9BXCrtkDvEwTwyS1ZFi922cdyP8uSj0VGURcFuttT+e8wYfkQhXgf0EaYIo1U02YlNj183pYPjfc3Es6A39tHsid3FEEOGlLvTmEcHpAJeqBGbVmGHASYrskLr24zdpLe6EGLvuEmbXKZSOYmhfVPsvc5h8KCL55RthXkoANtqIbcQ== ceph@ceph001.cubone.os");
"/software/components/useraccess/users/ceph/ssh_keys" = {
    foreach(idx;pubkey;CEPH_DEPLOY_PUBKEYS) {
        append(pubkey);
    };
    SELF;
};


variable CEPH_HOSTS = list('ceph001', 'ceph002', 'ceph003');
variable CEPH_OSD_DISKS = list('sdc','sdd','sde','sdf','sdg','sdh','sdi','sdj','sdk','sdl','sdm','sdn');
variable CEPH_JOURNAL_DISKS = list('sda4','sdb');
variable CEPH_DEFAULT_OSD_WEIGHT = to_double(value(format('/hardware/harddisks/%s/capacity', CEPH_OSD_DISKS[0]))) / (1024*1024);

variable MDSS = nlist (
    'ceph001.cubone.os', nlist(
        'fqdn', 'ceph001.cubone.os',
        ),
    'ceph002.cubone.os', nlist(
        'fqdn', 'ceph002.cubone.os',
    )
);
variable MONITOR1 =  nlist(
    'up', true,
    'fqdn', 'ceph001.cubone.os',
);
variable MONITOR2 =  nlist(
    'up', true,
    'fqdn', 'ceph002.cubone.os',
);
variable MONITOR3 =  nlist(
    'up', false,
    'fqdn', 'ceph003.cubone.os',
);

variable CONFIG = nlist (
    'fsid' , '82766e04-585b-49a6-a0ac-c13d9ffd0a7d',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003'),
    'public_network', '10.141.8.0/24',
    'cluster_network', '10.143.8.0/24',
    'osd_pool_default_size', 3,
    'osd_pool_default_min_size', 2,
    'osd_pool_default_pg_num', 400,
    'osd_pool_default_pgp_num', 400, 
);

prefix '/software/components/ceph';
'ceph_version'   =  '0.72.2';
'deploy_version' = '1.3.5';

'/software/packages' = pkg_repl("ceph*",format("%s-*",value('/software/components/ceph/ceph_version')),'x86_64');
'/software/packages' = pkg_repl("ceph-deploy",format("%s-*",value('/software/components/ceph/deploy_version')),'noarch');


prefix '/software/components/ceph/clusters/ceph';

'crushmap' = nlist(
    'types' , list('osd','host','root'),
    'rules', list (
        nlist(
            'name', 'data',
            'steps', list(
                nlist(
                    'take', 'default', 
                    'choices', list(
                        nlist(
                            'chtype', 'chooseleaf firstn',
                            'bktype', 'host'
                        ),
                    ),
                ),
            ),
        ),
        nlist(
            'name', 'metadata',
            'steps', list(
                nlist(
                    'take', 'default', 
                    'choices', list(
                        nlist(
                            'chtype', 'chooseleaf firstn',
                            'bktype', 'host'
                        ),
                    ),
                ),
            ),
        ),
        nlist(
            'name', 'rbd',
            'steps', list(
                nlist(
                    'take', 'default', 
                    'choices', list(
                        nlist(
                            'chtype', 'chooseleaf firstn',
                            'bktype', 'host'
                        ),
                    ),
                ),
            ),
        ),
    ),
    'buckets', list(
        nlist(
            'name', 'default',
            'type', 'root',
            'hash', 0,
            'buckets', list(
                nlist(
                    'name', 'ceph001',
                    'type', 'host',
                    'hash', 0,
                ),
                nlist(
                    'name', 'ceph002',
                    'type', 'host',
                    'hash', 0,
                ),
                nlist(
                    'name', 'ceph003',
                    'type', 'host',
                    'hash', 0,
                ),
            ),
        ),
    ),
);

'config' = CONFIG;
'osdhosts' = {
    t=nlist();    
    foreach(idx;host;CEPH_HOSTS) {
        d = nlist();
        foreach(odx;disk;CEPH_OSD_DISKS) {
            jdx= odx % length(CEPH_JOURNAL_DISKS); ## RR over journal disks
            d[disk] = nlist(
                'journal_path', format('/var/lib/ceph/log/%s/osd-%s/journal', CEPH_JOURNAL_DISKS[jdx], disk),
                'crush_weight', CEPH_DEFAULT_OSD_WEIGHT
            );
        };
        t[host] = nlist(
            'fqdn', format('%s.%s', host, value('/system/network/domainname')),
            'osds', d
        );
    };
    t;
};

'mdss' = MDSS;
'monitors' = nlist (
    'ceph001', MONITOR1,
    'ceph002', MONITOR2,
    'ceph003', MONITOR3
);
'deployhosts' = nlist (
    'ceph001', 'ceph001.cubone.os',
);  
