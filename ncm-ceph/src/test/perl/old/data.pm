# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod
=head1 ceph data examples
# Test the runs of ceph commands

=cut

package data;

use strict;
use warnings;

use Readonly;

Readonly our $CATCMD => '/bin/cat';
Readonly our $OSD_SSH_BASE_CMD => 'su - ceph -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r ceph001.cubone.os';

Readonly::Hash our  %MONJSONDECODE => (
    'created' => '0.000000',
    'epoch' => 11,
    'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'modified' => '2013-12-11 10:40:44.403149',
    'mons' => [
        {
        'addr' => '10.141.8.181:6754/0',
        'name' => 'ceph002',
        'rank' => 0
        },
        {
        'addr' => '10.141.8.180:6789/0',
        'name' => 'ceph001',
        'rank' => 1
        },
        {
        'addr' => '10.141.8.182:6789/0',
        'name' => 'ceph003',
        'rank' => 2
        }
    ],
    'quorum' => [
        0,
        1,
        2
    ]
);

Readonly our $MONJSON => '{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}],"quorum":[0,1,2]}';

Readonly our $OSDTJSON => '{"nodes":[{"id":-1,"name":"default","type":"root","type_id":6,"children":[-2]},{"id":-2,"name":"ceph001","type":"host","type_id":1,"children":[1,0]},{"id":0,"name":"osd.0","exists":1,"type":"osd","type_id":0,"status":"up","reweight":"1.000000","crush_weight":"3.639999","depth":2},{"id":1,"name":"osd.1","exists":1,"type":"osd","type_id":0,"status":"up","reweight":"1.000000","crush_weight":"3.639999","depth":2}],"stray":[]}';

Readonly our $OSDDJSON => '{ "epoch": 11,
  "fsid": "e2177713-df22-48f7-a55a-45ac37e4b5e0",
  "created": "2014-01-21 14:57:37.202763",
  "modified": "2014-01-24 15:48:32.847771",
  "flags": "",
  "cluster_snapshot": "",
  "pool_max": 2,
  "max_osd": 2,"osds": [
        { "osd": 0,
          "uuid": "e2fa588a-8c6c-4874-b76d-597299ecdf72",
          "up": 1,
          "in": 1,
          "weight": "1.000000",
          "last_clean_begin": 0,
          "last_clean_end": 0,
          "up_from": 4,
          "up_thru": 4,
          "down_at": 0,
          "lost_at": 0,
          "public_addr": "10.141.8.180:6800\/31264",
          "cluster_addr": "10.141.8.180:6801\/31264",
          "heartbeat_back_addr": "10.141.8.180:6802\/31264",
          "heartbeat_front_addr": "10.141.8.180:6803\/31264",
          "state": [
                "exists",
                "up"]},
        { "osd": 1,
          "uuid": "ae77eef3-70a2-4b64-b795-2dee713bfe41",
          "up": 1,
          "in": 1,
          "weight": "3.000000",
          "last_clean_begin": 0,
          "last_clean_end": 0,
          "up_from": 8,
          "up_thru": 10,
          "down_at": 0,
          "lost_at": 0,
          "public_addr": "10.141.8.180:6805\/47442",
          "cluster_addr": "10.141.8.180:6806\/47442",
          "heartbeat_back_addr": "10.141.8.180:6807\/47442",
          "heartbeat_front_addr": "10.141.8.180:6808\/47442",
          "state": [
                "exists",
                "up"]}]
}';

Readonly our $MDSJSON => '
{ "mdsmap": { "epoch": 13,
      "flags": 0,
      "created": "2014-01-21 14:57:37.202097",
      "modified": "2014-01-28 15:27:10.886643",
      "tableserver": 0,
      "root": 0,
      "session_timeout": 60,
      "session_autoclose": 300,
      "max_file_size": 1099511627776,
      "last_failure": 6,
      "last_failure_osd_epoch": 27,
      "compat": { "compat": {},
          "ro_compat": {},
          "incompat": { "feature_1": "base v0.20",
              "feature_2": "client writeable ranges",
              "feature_3": "default file layouts on dirs",
              "feature_4": "dir inode in separate object",
              "feature_5": "mds uses versioned encoding"}},
      "max_mds": 1,
      "in": [
            0],
      "up": { "mds_0": 4665},
      "failed": [],
      "stopped": [],
      "info": { 
          "gid_5047": { "gid": 5047,
              "name": "ceph001",
              "rank": -1,
              "incarnation": 0,
              "state": "up:standby",
              "state_seq": 1,
              "addr": "10.141.8.180:6810\/37555",
              "standby_for_rank": -1,
              "standby_for_name": "",
              "export_targets": []}},
      "data_pools": [
            0],
      "metadata_pool": 1},
  "mdsmap_first_committed": 1}
';

Readonly our $FSID => 'a94f9906-ff68-487d-8193-23ad04c1b5c4';

Readonly::Hash our %MONS => ( 
   'ceph001' => {
     'fqdn' => 'ignore',
     'mon' => {
       'addr' => '10.141.8.180:6789/0',
       'fqdn' => 'ignore',
       'name' => 'ceph001',
       'rank' => 1,
       'up' => 1
     }
   },
   'ceph002' => {
     'fqdn' => 'ignore',
     'mon' => {
       'addr' => '10.141.8.181:6754/0',
       'fqdn' => 'ignore',
       'name' => 'ceph002',
       'rank' => 0,
       'up' => 1
     }
   },
   'ceph003' => {
     'fqdn' => 'ignore',
     'mon' => {
       'addr' => '10.141.8.182:6789/0',
       'fqdn' => 'ignore',
       'name' => 'ceph003',
       'rank' => 2,
       'up' => ''
     }
   }

);

Readonly::Hash our %OSDS => ( 
   'ceph001' => {
     'fault' => 0,
     'fqdn' => 'ceph001.cubone.os',
     'osds' => {
       'ceph001:/var/lib/ceph/osd/sdc' => {
         'host' => 'ceph001',
         'id' => 0,
         'in' => 1,
         'ip' => '10.141.8.180',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
         'name' => 'osd.0',
         'osd_path' => '/var/lib/ceph/osd/sdc',
         'up' => 1,
         'uuid' => 'e2fa588a-8c6c-4874-b76d-597299ecdf72'
       },
       'ceph001:/var/lib/ceph/osd/sdd' => {
         'host' => 'ceph001',
         'id' => 1,
         'in' => 1,
         'ip' => '10.141.8.180',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdd/journal',
         'name' => 'osd.1',
         'osd_path' => '/var/lib/ceph/osd/sdd',
         'up' => 1,
         'uuid' => 'ae77eef3-70a2-4b64-b795-2dee713bfe41'
       }
     }
   }
);

Readonly::Hash our %FLATTEN => (
   'ceph001:/var/lib/ceph/osd/sdc' => {
     'fqdn' => 'ceph001.cubone.os',
     'host' => 'ceph001',
     'osd_path' => '/var/lib/ceph/osd/sdc'
   },
   'ceph001:/var/lib/ceph/osd/sdd' => {
     'fqdn' => 'ceph001.cubone.os',
     'host' => 'ceph001',
     'journal_path' => '/var/lib/ceph/log/sda4/osd-sdd/journal',
     'osd_path' => '/var/lib/ceph/osd/sdd'
   },
   'ceph002:/var/lib/ceph/osd/sdc' => {
     'fqdn' => 'ceph002.cubone.os',
     'host' => 'ceph002',
     'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
     'osd_path' => '/var/lib/ceph/osd/sdc'
   }
 );

Readonly::Hash our %MDSS => ( 
   'ceph001' => {
     'fqdn' => 'ceph001.cubone.os',
     'mds' => {
       'fqdn' => 'ceph001.cubone.os',
       'gid' => 5047,
       'name' => 'ceph001',
       'up' => 1
     }
   }
);


Readonly::Hash our %MAPPING => ( 
    'get_id' => {
      'ceph001:/var/lib/ceph/osd/sdc' => 0,
      'ceph001:/var/lib/ceph/osd/sdd' => 1
    },  
    'get_loc' => {
      '0' => 'ceph001:/var/lib/ceph/osd/sdc',
      '1' => 'ceph001:/var/lib/ceph/osd/sdd'
    }   
);
Readonly::Hash our %WEIGHTS => (
   'osd.0' => '3.639999',
   'osd.1' => '3.639999'
);
 
Readonly::Hash our %CEPHMAP => (
   'ceph001' => {
     'config' => {
       'fsid' => 'e2fa588a-8c6c-4874-b76d-597299ecdf72'
     },
     'fault' => 0,
     'fqdn' => 'ceph001.cubone.os',
     'mon' => {
        'config' => {
         'option' => 'value'
        },
     },
     'osds' => {
       'ceph001:/var/lib/ceph/osd/sdc' => {
         'config' => {
           'osd_objectstore' => 'keyvaluestore-dev'
         },
         'host' => 'ceph001',
         'id' => 0,
         'in' => 1,
         'ip' => '10.141.8.180',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
         'name' => 'osd.0',
         'osd_path' => '/var/lib/ceph/osd/sdc',
         'up' => 1,
         'uuid' => 'e2fa588a-8c6c-4874-b76d-597299ecdf72'
       },
       'ceph001:/var/lib/ceph/osd/sdd' => {
         'host' => 'ceph001',
         'id' => 1,
         'in' => 1,
         'ip' => '10.141.8.180',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdd/journal',
         'name' => 'osd.1',
         'osd_path' => '/var/lib/ceph/osd/sdd',
         'up' => 1,
         'uuid' => 'ae77eef3-70a2-4b64-b795-2dee713bfe41'
       }
     }
   }
);
Readonly::Hash our %QUATMAP => (
   'ceph001' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => [
         'ceph001',
         'ceph002',
         'ceph003'
       ]
     },
     'fqdn' => 'ceph001.cubone.os',
     'mon' => {
       'fqdn' => 'ceph001.cubone.os',
       'up' => 1
     },
     'osds' => {
       'ceph001:/var/lib/ceph/osd/sdc' => {
         'fqdn' => 'ceph001.cubone.os',
         'host' => 'ceph001',
         'osd_path' => '/var/lib/ceph/osd/sdc'
       },
       'ceph001:/var/lib/ceph/osd/sdd' => {
         'fqdn' => 'ceph001.cubone.os',
         'host' => 'ceph001',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdd/journal',
         'osd_path' => '/var/lib/ceph/osd/sdd'
       }
     }
   },
   'ceph002' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => [
         'ceph001',
         'ceph002',
         'ceph003'
       ]
     }, 
     'fqdn' => 'ceph002.cubone.os',
     'mds' => {
       'fqdn' => 'ceph002.cubone.os',
       'up' => 1
     },
     'mon' => {
       'fqdn' => 'ceph002.cubone.os',
       'up' => 1
     },
     'osds' => {
       'ceph002:/var/lib/ceph/osd/sdc' => {
         'fqdn' => 'ceph002.cubone.os',
         'host' => 'ceph002',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
         'osd_path' => '/var/lib/ceph/osd/sdc'
       }
     }
   },
   'ceph003' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => [
         'ceph001',
         'ceph002',
         'ceph003'
       ]
     }, 
     'fqdn' => 'ceph003.cubone.os',
     'mon' => {
       'fqdn' => 'ceph003.cubone.os',
       'up' => 1
     }
   }
);
our %QUATIN = (
   'ceph001' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => [
         'ceph001',
         'ceph002',
         'ceph003'
       ]
     },
     'fqdn' => 'ceph001.cubone.os',
     'mon' => {
       'config' => {
           'debug_ms' => 0,
       },
       'fqdn' => 'ceph001.cubone.os',
       'up' => 1
     },
     'osds' => {
       'ceph001:/var/lib/ceph/osd/sdc' => {
         'config' => {
           'osd_objectstore' => 'keyvaluestore-dev'
         },
         'fqdn' => 'ceph001.cubone.os',
         'up' => 1,
         'host' => 'ceph001',
         'osd_path' => '/var/lib/ceph/osd/sdc'
       },
       'ceph001:/var/lib/ceph/osd/sdd' => {
         'fqdn' => 'ceph001.cubone.os',
          'up' => 0,
         'host' => 'ceph001',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdd/journal',
         'osd_path' => '/var/lib/ceph/osd/sdd'
       }
     }
   },
   'ceph002' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => [
         'ceph001',
         'ceph002',
         'ceph003'
       ]
     },
     'fqdn' => 'ceph002.cubone.os',
     'mds' => {
       'fqdn' => 'ceph002.cubone.os',
       'up' => 1
     },
     'mon' => {
       'fqdn' => 'ceph002.cubone.os',
       'up' => 1
     },
     'osds' => {
       'ceph002:/var/lib/ceph/osd/sdc' => {
         'config' => {
           'osd_objectstore' => 'keyvaluestore-dev'
         },
         'fqdn' => 'ceph002.cubone.os',
         'host' => 'ceph002',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
         'osd_path' => '/var/lib/ceph/osd/sdc'
       }
     }
   },
   'ceph003' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => [
         'ceph001',
         'ceph002',
         'ceph003'
       ]
     },
     'fqdn' => 'ceph003.cubone.os',
     'mon' => {
       'fqdn' => 'ceph003.cubone.os',
       'up' => 1
     },
     'osds' => {
       'ceph003:/var/lib/ceph/osd/sdc' => {
         'fqdn' => 'ceph003.cubone.os',
         'host' => 'ceph003',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
         'osd_path' => '/var/lib/ceph/osd/sdc'
       }
     }
   }
);
Readonly::Hash our %CEPHFMAP => (
   'ceph001' => {
     'config' => {
       'fsid' => 'e2fa588a-8c6c-4874-b76d-597299ecdf72'
     },
     'fault' => 0,
     'fqdn' => 'ceph001.cubone.os',
     'mds' => {
       'fqdn' => 'ceph001.cubone.os',
       'gid' => 5047,
       'name' => 'ceph001',
       'up' => 1
     },
     'mon' => {
       'addr' => '10.141.8.180:6789/0',
       'config' => {
         'option' => 'value'
       },
       'fqdn' => 'ceph001.cubone.os',
       'name' => 'ceph001',
       'rank' => 1,
       'up' => 1
     },
     'osds' => {
       'ceph001:/var/lib/ceph/osd/sdc' => {
         'config' => {
           'osd_objectstore' => 'keyvaluestore-dev'
         },
         'host' => 'ceph001',
         'id' => 0,
         'in' => 1,
         'ip' => '10.141.8.180',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
         'name' => 'osd.0',
         'osd_path' => '/var/lib/ceph/osd/sdc',
         'up' => 1,
         'uuid' => 'e2fa588a-8c6c-4874-b76d-597299ecdf72'
       },
       'ceph001:/var/lib/ceph/osd/sdd' => {
         'host' => 'ceph001',
         'id' => 1,
         'in' => 1,
         'ip' => '10.141.8.180',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdd/journal',
         'name' => 'osd.1',
         'osd_path' => '/var/lib/ceph/osd/sdd',
         'up' => 1,
         'uuid' => 'ae77eef3-70a2-4b64-b795-2dee713bfe41'
       }
     }
   },
   'ceph002' => {
     'config' => undef,
     'fqdn' => 'ceph002.cubone.os',
     'mon' => {
       'addr' => '10.141.8.181:6754/0',
       'fqdn' => 'ceph002.cubone.os',
       'name' => 'ceph002',
       'rank' => 0,
       'up' => 1
     }
   },
   'ceph003' => {
     'fault' => 1,
     'fqdn' => 'ceph003.cubone.os',
     'mon' => {
       'addr' => '10.141.8.182:6789/0',
       'fqdn' => 'ceph003.cubone.os',
       'name' => 'ceph003',
       'rank' => 2,
       'up' => ''
     }
   }
);
our %CEPHINGW = ( 
   'ceph001' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4'
     },  
     'fault' => 0,
     'fqdn' => 'ceph001.cubone.os',
     'mon' => {
       'addr' => '10.141.8.180:6789/0',
       'fqdn' => 'ceph001.cubone.os',
       'name' => 'ceph001',
       'rank' => 1,
       'up' => 1
     },  
  }
);
Readonly::Hash our %QUATMAPGW => (
   'ceph001' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => [
         'ceph001',
         'ceph002',
         'ceph003'
       ]
     },
     'fqdn' => 'ceph001.cubone.os',
     'mon' => {
       'fqdn' => 'ceph001.cubone.os',
       'up' => 1
     },
     'gtws' => {
       'gateway' => {
         'config' => {
           'foo' => 'bar',
           'host' => 'ceph001'
         }
       }
     },
   }
);
Readonly::Hash our  %COMPARE1GW => (
     'ceph001' => {
       'client.radosgw.gateway' => {
         'foo' => 'bar',
         'host' => 'ceph001'
      },
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       }
     }
);
our %CEPHIN = (
   'ceph001' => {
     'config' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4'
     },
     'fault' => 0,
     'fqdn' => 'ceph001.cubone.os',
     'mds' => {
       'fqdn' => 'ceph001.cubone.os',
       'gid' => 5047,
       'name' => 'ceph001',
       'up' => 1
     },
     'mon' => {
       'config' => {
           'debug_ms' => 15,
       },
       'addr' => '10.141.8.180:6789/0',
       'fqdn' => 'ceph001.cubone.os',
       'name' => 'ceph001',
       'rank' => 1,
       'up' => 1
     },
     'osds' => {
       'ceph001:/var/lib/ceph/osd/sdc' => {
         'config' => {
           'osd_objectstore' => 'keyvaluestore-dev'
         },
         'host' => 'ceph001',
         'id' => 0,
         'in' => 1,
         'ip' => '10.141.8.180',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
         'name' => 'osd.0',
         'osd_path' => '/var/lib/ceph/osd/sdc',
         'up' => 1,
         'uuid' => 'e2fa588a-8c6c-4874-b76d-597299ecdf72'
       },
       'ceph001:/var/lib/ceph/osd/sdd' => {
         'host' => 'ceph001',
         'id' => 1,
         'in' => 1,
         'ip' => '10.141.8.180',
         'journal_path' => '/var/lib/ceph/log/sda4/osd-sdd/journal',
         'name' => 'osd.1',
         'osd_path' => '/var/lib/ceph/osd/sdd',
         'up' => 1,
         'uuid' => 'ae77eef3-70a2-4b64-b795-2dee713bfe41'
       }
     }
   },
   'ceph002' => {
     'config' => undef,
     'fqdn' => 'ceph002.cubone.os',
     'mon' => {
       'addr' => '10.141.8.181:6754/0',
       'fqdn' => 'ceph002.cubone.os',
       'name' => 'ceph002',
       'rank' => 0,
       'up' => 1
     }
   },
);
Readonly::Array our @NEWCLUS => (
#   [
#     '/usr/bin/ceph-deploy',
#     'new',
#     'ceph001.cubone.os',
#     'ceph002.cubone.os',
#     'ceph003.cubone.os'
#   ],
   [
     '/usr/bin/ceph-deploy',
     'mon',
     'create-initial'
   ],
);

Readonly our $STATE => '{"election_epoch":34,"quorum":[0,1],"quorum_names":["ceph001","ceph002"],"quorum_leader_name":"ceph002","monmap":{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}]}}';

Readonly::Hash our %COMPARE1 => (
   'configs' => {
     'ceph001' => {
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       },
       'mon' => {
         'debug_ms' => 0
       },
       'osd.0' => {
         'osd_objectstore' => 'keyvaluestore-dev'
       }
     },
     'ceph002' => {
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       }
     }
   },
   'deployd' => {
     'ceph001' => {
       'fqdn' => 'ceph001.cubone.os'
     },
     'ceph002' => {
       'fqdn' => 'ceph002.cubone.os',
       'osds' => {
         'ceph002:/var/lib/ceph/osd/sdc' => {
           'config' => {
             'osd_objectstore' => 'keyvaluestore-dev'
           },
           'fqdn' => 'ceph002.cubone.os',
           'host' => 'ceph002',
           'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
           'osd_path' => '/var/lib/ceph/osd/sdc'
         }
       }
     }
   },
   'destroy' => {
     'ceph001' => {
       'mds' => {
         'fqdn' => 'ceph001.cubone.os',
         'gid' => 5047,
         'name' => 'ceph001',
         'up' => 1
       }
     }
   },
   'gvalues' => {},
   'skip' => {
     'ceph003' => {
       'config' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       },
       'fqdn' => 'ceph003.cubone.os',
       'mon' => {
         'fqdn' => 'ceph003.cubone.os',
         'up' => 1
       },
       'osds' => {
         'ceph003:/var/lib/ceph/osd/sdc' => {
            'fqdn' => 'ceph003.cubone.os',
            'host' => 'ceph003',
            'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
            'osd_path' => '/var/lib/ceph/osd/sdc'
            }
        }
     }
   },
   'mapping' => {
     'get_id' => {
       'ceph001:/var/lib/ceph/osd/sdc' => 0,
       'ceph001:/var/lib/ceph/osd/sdd' => 1
     },
     'get_loc' => {
       '0' => 'ceph001:/var/lib/ceph/osd/sdc',
       '1' => 'ceph001:/var/lib/ceph/osd/sdd'
     }
   },
   'restartd' => {
     'ceph001' => {
       'mon' => 'restart',
       'osd.1' => 'stop'
     },
     'ceph002' => {
       'mds' => 'start'
     }
   }
);
Readonly::Hash our %COMPARE2 => (
   'configs' => {
     'ceph001' => {
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       },
       'mon' => {
         'debug_ms' => 0
       },
       'osd.0' => {
         'osd_objectstore' => 'keyvaluestore-dev'
       }
     },
     'ceph002' => {
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       }
     },
     'ceph003' => {
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       }
     }
   },
   'deployd' => {
     'ceph001' => {
       'fqdn' => 'ceph001.cubone.os'
     },
     'ceph002' => {
       'fqdn' => 'ceph002.cubone.os',
       'mds' => {
         'fqdn' => 'ceph002.cubone.os',
         'up' => 1
       },
       'osds' => {
         'ceph002:/var/lib/ceph/osd/sdc' => {
           'config' => {
             'osd_objectstore' => 'keyvaluestore-dev'
           },
           'fqdn' => 'ceph002.cubone.os',
           'host' => 'ceph002',
           'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
           'osd_path' => '/var/lib/ceph/osd/sdc'
         }
       }
     },
     'ceph003' => {
       'fqdn' => 'ceph003.cubone.os',
       'mon' => {
         'fqdn' => 'ceph003.cubone.os',
         'up' => 1
       },
       'osds' => {
         'ceph003:/var/lib/ceph/osd/sdc' => {
           'fqdn' => 'ceph003.cubone.os',
           'host' => 'ceph003',
           'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
           'osd_path' => '/var/lib/ceph/osd/sdc'
         }
       }
     }
   },
   'destroy' => {
     'ceph001' => {
       'mds' => {
         'fqdn' => 'ceph001.cubone.os',
         'gid' => 5047,
         'name' => 'ceph001',
         'up' => 1
       }
     }
   },
   'gvalues' => {max_add_osd_failures_per_host => 1},
   'skip' => {},
   'mapping' => {
     'get_id' => {
       'ceph001:/var/lib/ceph/osd/sdc' => 0,
       'ceph001:/var/lib/ceph/osd/sdd' => 1
     },
     'get_loc' => {
       '0' => 'ceph001:/var/lib/ceph/osd/sdc',
       '1' => 'ceph001:/var/lib/ceph/osd/sdd'
     }
   },
   'restartd' => {
     'ceph001' => {
       'mon' => 'restart',
       'osd.1' => 'stop'
     }
   }
);
Readonly::Hash our %CONFIGS => (
     'ceph001' => {
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       },
       'mon' => {
         'debug_ms' => 0
       },
       'osd.0' => {
         'osd_objectstore' => 'keyvaluestore-dev'
       }
     },  
     'ceph002' => {
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       }
     },  
     'ceph003' => {
       'global' => {
         'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
         'mon_initial_members' => [
           'ceph001',
           'ceph002',
           'ceph003'
         ]
       }
     }   
);

Readonly::Hash our %TINIES => (
   'ceph001' => {
     'global' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => 'ceph001, ceph002, ceph003'
     },
     'mon' => {
       'debug_ms' => 0
     },
     'osd.0' => {
       'osd_objectstore' => 'keyvaluestore-dev'
     }
   },
   'ceph002' => {
     'global' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => 'ceph001, ceph002, ceph003'
     },
     'osd.2' => {
       'osd_objectstore' => 'keyvaluestore-dev'
     }
   },
   'ceph003' => {
     'global' => {
       'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
       'mon_initial_members' => 'ceph001, ceph002, ceph003'
     }
   }
); 

Readonly::Hash our %MAPADD => (
    'get_id' => {
      'ceph002:/var/lib/ceph/osd/sdc' => '2'
    },
    'get_loc' => {
      '2' => 'ceph002:/var/lib/ceph/osd/sdc'
    }
);

Readonly::Hash our %DEPLOYD => (
     'ceph002' => {
       'mds' => {
         'fqdn' => 'ceph002.cubone.os',
         'up' => 1
       },
       'osds' => {
         'ceph002:/var/lib/ceph/osd/sdc' => {
           'config' => {
             'osd_objectstore' => 'keyvaluestore-dev'
           },
           'fqdn' => 'ceph002.cubone.os',
           'host' => 'ceph002',
           'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
           'osd_path' => '/var/lib/ceph/osd/sdc'
         }
       }
     },  
     'ceph003' => {
       'mon' => {
         'fqdn' => 'ceph003.cubone.os',
         'up' => 1
       }
     }  
);
Readonly::Hash our %DESTROYD => (
     'ceph001' => {
       'mds' => {
         'fqdn' => 'ceph001.cubone.os',
         'gid' => 5047,
         'name' => 'ceph001',
         'up' => 1
       },
       'osds' => {
         'ceph001:/var/lib/ceph/osd/sdc' => {
           'config' => {
             'osd_objectstore' => 'keyvaluestore-dev'
           },
           'host' => 'ceph001',
           'id' => 0,
           'in' => 1,
           'ip' => '10.141.8.180',
           'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
           'name' => 'osd.0',
           'osd_path' => '/var/lib/ceph/osd/sdc',
           'up' => 1,
           'uuid' => 'e2fa588a-8c6c-4874-b76d-597299ecdf72'
         },
       },
       'config' => {
            'some' => 'value'
       }, 
     }, 
); 
Readonly::Hash our %RESTARTD => (
     'ceph001' => {
       'mon' => 'restart',
       'osd.1' => 'stop'
     },
     'ceph002' => {
       'mds' => 'start'
     }
);
