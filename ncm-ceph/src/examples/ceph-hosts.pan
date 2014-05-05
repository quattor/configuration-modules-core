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
"{redhat-lsb}" = nlist();

variable OS_REPOSITORY_LIST = append('ceph-deploy');
variable OS_REPOSITORY_LIST = append('ceph-extras-noarch');
variable OS_REPOSITORY_LIST = append('ceph-extras');
variable OS_REPOSITORY_LIST = append('ceph-noarch');
variable OS_REPOSITORY_LIST = append('ceph-testing');
variable OS_REPOSITORY_LIST = append('ceph-testing-noarch');
variable OS_REPOSITORY_LIST = append('ceph');

## add ceph user

include 'components/accounts/config';
include 'components/sudo/config';
include 'components/ceph/ceph-user';
include 'components/ceph/sudo';

"/software/components/chkconfig/service/ceph/on" = "";

final variable CEPH_DEPLOY_PUBKEYS = list(
"ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAt/NFRkQ1lsTMpEsucmob+67YgKbUWEXtE8gZZ/SD1MIFNS1MCniaGC5bCD61YadGgG0yd0mQxEbzg3jPnMjhYG0mHGtGeKkfFMIw/RxpHfb635I+aA1w9LczfQ2qYYZ4bcMqZI5K0kNdgyL9tkutY3tL6nAy2iscqcek7NdqW872ddoRn2LmOejpTKIcEs3Ya405yw/gcf0R+9bN+lELHxy/mlXE6XY1LjxXF5CKrsDicg8TyoFg/zMxLH0C0EeTpW4ubijw46GoCFBEWJjLR9YwgzFKFK4xzVYaTPcCnRF6aLUBpUVDrAXiNDYFUSMeNaIWb51MDCyJulAFPGmqcQ== ceph@ceph001.cubone.os"
);
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
'ceph_version'   =  '0.79';
'deploy_version' = '1.3.5';

'/software/packages' = pkg_repl("ceph*",format("%s-*",value('/software/components/ceph/ceph_version')),'x86_64');
'/software/packages' = pkg_repl("ceph-deploy",format("%s-*",value('/software/components/ceph/deploy_version')),'noarch');


prefix '/software/components/ceph/clusters/ceph/crushmap';

variable BASE_CHOICES = list(
    nlist(
        'chtype', 'chooseleaf firstn',
        'bktype', 'host',
    ),
);

'types' = list('osd','host','root');
'tunables' = nlist(
    'choose_local_tries', 0,
    'choose_local_fallback_tries', 0,
    'choose_total_tries', 50, 
    'chooseleaf_descend_once', 1
);

'rules/0/name' = 'data';
'rules/0/type' = 'replicated';
'rules/0/steps/0/take' = 'default-sas';
'rules/0/steps/0/choices' = BASE_CHOICES;

'rules/1/name' = 'metadata';
'rules/1/type' = 'replicated';
'rules/1/steps/0/take' = 'default-ssd';
'rules/1/steps/0/choices' = BASE_CHOICES;
    
'rules/2/name' = 'rbd';
'rules/2/type' = 'replicated';
'rules/2/steps/0/take' = 'default-sas';
'rules/2/steps/0/choices' = BASE_CHOICES;

'buckets/0/name' = 'default';
'buckets/0/type' = 'root';
'buckets/0/labels' = list('ssd','sas');
'buckets/0/buckets' = list(
    nlist(
        'name', 'ceph001',
        'type', 'host',
    ),  
    nlist(
        'name', 'ceph002',
        'type', 'host',
    ),  
    nlist(
        'name', 'ceph003',
        'type', 'host',
    ),
);

prefix '/software/components/ceph/clusters/ceph';
'config' = CONFIG;
'osdhosts' = {
    t=nlist();    
    foreach(idx;host;CEPH_HOSTS) {
        d = nlist();
        foreach(odx;disk;CEPH_OSD_DISKS) {
            jdx= odx % length(CEPH_JOURNAL_DISKS); ## RR over journal disks
            d[disk] = nlist(
                'journal_path', format('/var/lib/ceph/log/%s/osd-%s/journal', CEPH_JOURNAL_DISKS[jdx], disk),
                'crush_weight', CEPH_DEFAULT_OSD_WEIGHT,
                'labels', list('sas'),
            );
        };
        foreach(odx;disk;CEPH_JOURNAL_DISKS) {
            d[disk] = nlist(
                'crush_weight', CEPH_DEFAULT_OSD_WEIGHT,
                'labels', list('ssd'),
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
