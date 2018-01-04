package clmapdata;

use strict;
use warnings;

use Readonly;

Readonly our $MONJSON => '{"epoch":3,"fsid":"d3da1b0d-60a1-41bc-adb1-7df8191c16a7","modified":"2017-12-21 17:37:18.501945","created":"2017-07-26 14:53:14.536439","features":{"persistent":["kraken","luminous"],"optional":[]},"mons":[{"rank":0,"name":"ceph001","addr":"10.141.8.180:6789/0","public_addr":"10.141.8.180:6789/0"},{"rank":1,"name":"ceph002","addr":"10.141.8.181:6789/0","public_addr":"10.141.8.181:6789/0"}],"quorum":[0,1]}';

Readonly our $MGRJSON => '{"epoch":747726,"active_gid":64825,"active_name":"ceph001","active_addr":"10.141.8.180:6800/1165","available":true,"standbys":[{"gid":124243,"name":"ceph002","available_modules":["balancer","dashboard","influx","localpool","prometheus","restful","selftest","status","zabbix"]}],"modules":["restful","status"],"available_modules":["balancer","dashboard","influx","localpool","prometheus","restful","selftest","status","zabbix"],"services":{}}';

Readonly our $MDSJSON => '{"fsmap":{"epoch":5,"compat":{"compat":{},"ro_compat":{},"incompat":{"feature_1":"base v0.20","feature_2":"client writeable ranges","feature_3":"default file layouts on dirs","feature_4":"dir inode in separate object","feature_5":"mds uses versioned encoding","feature_6":"dirfrag is stored in omap","feature_8":"file layout v2"}},"feature_flags":{"enable_multiple":false,"ever_enabled_multiple":false},"standbys":[{"gid":114315,"name":"ceph001","rank":-1,"incarnation":0,"state":"up:standby","state_seq":2,"addr":"10.141.8.180:6801/1804487643","standby_for_rank":-1,"standby_for_fscid":-1,"standby_for_name":"","standby_replay":false,"export_targets":[],"features":2305244844532236283,"epoch":2}],"filesystems":[{"mdsmap":{"epoch":5,"flags":12,"ever_allowed_features":0,"explicitly_allowed_features":0,"created":"2017-12-20 11:44:05.900981","modified":"2017-12-20 11:44:05.900981","tableserver":0,"root":0,"session_timeout":60,"session_autoclose":300,"max_file_size":1099511627776,"last_failure":0,"last_failure_osd_epoch":0,"compat":{"compat":{},"ro_compat":{},"incompat":{"feature_1":"base v0.20","feature_2":"client writeable ranges","feature_3":"default file layouts on dirs","feature_4":"dir inode in separate object","feature_5":"mds uses versioned encoding","feature_6":"dirfrag is stored in omap","feature_8":"file layout v2"}},"max_mds":1,"in":[0],"up":{"mds_0":114330},"failed":[],"damaged":[],"stopped":[],"info":{"gid_114330":{"gid":114330,"name":"ceph002","rank":0,"incarnation":5,"state":"up:creating","state_seq":2,"addr":"10.141.8.181:6812/2321221980","standby_for_rank":-1,"standby_for_fscid":-1,"standby_for_name":"","standby_replay":false,"export_targets":[],"features":2305244844532236283}},"data_pools":[1],"metadata_pool":2,"enabled":true,"fs_name":"cephfs","balancer":"","standby_count_wanted":0},"id":1}]},"mdsmap_first_committed":1,"mdsmap_last_committed":5}';

Readonly our %CEPH_HASH => (
   'ceph001' => {
     'mds' => {},
     'mgr' => {},
     'mon' => {
       'addr' => '10.141.8.180:6789/0'
     }
    },
   'ceph002' => {
     'mds' => {},
     'mgr' => {},
     'mon' => {
       'addr' => '10.141.8.181:6789/0'
     }
   }
);


Readonly our %QUATTOR_HASH => (
    'ceph001' => {
        'fqdn' => 'ceph001.cubone.os',
        'daemons' => {
            'mgr' => {
                'fqdn' => 'ceph001.cubone.os'
            },
            'mon' => {
                'fqdn' => 'ceph001.cubone.os'
            },
        },
   },
    'ceph002' => {
        'fqdn' => 'ceph002.cubone.os',
        'daemons' => {
            'mds' => {
                'fqdn' => 'ceph002.cubone.os'
            },
            'mgr' => {
                'fqdn' => 'ceph002.cubone.os'
            },
            'mon' => {
                'fqdn' => 'ceph002.cubone.os'
            },
        },
   },
   'ceph003' => {
     'fqdn' => 'ceph003.cubone.os',
        'daemons' => {
            'mds' => {
                'fqdn' => 'ceph003.cubone.os'
            },
            'mgr' => {
                'fqdn' => 'ceph003.cubone.os'
            },
            'mon' => {
                'fqdn' => 'ceph003.cubone.os'
            },
        },
   }
);

Readonly our %DEPLOY_HASH => (
   'ceph001' => {
     'fqdn' => 'ceph001.cubone.os',
     'mon' => {
       'fqdn' => 'ceph001.cubone.os'
     }
   },
   'ceph003' => {
       'mds' => {
         'fqdn' => 'ceph003.cubone.os'
       },
       'mgr' => {
         'fqdn' => 'ceph003.cubone.os'
       },
       'mon' => {
         'fqdn' => 'ceph003.cubone.os'
       },
     'fqdn' => 'ceph003.cubone.os'
   }
);

Readonly our $SSH_FULL => '/usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r';
