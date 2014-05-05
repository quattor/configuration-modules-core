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
Readonly::Hash our  %MONJSONDECODE => (
    'created' => '0.000000',
    'epoch' => 11,
    'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'modified' => '2013-12-11 10:40:44.403149',
    'mons' => [
        {
        'addr' => '10.141.8.181:6754/0',
        'name' => 'ceph002b',
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

Readonly our $MONJSON => '{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002b","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}],"quorum":[0,1,2]}';

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
        'addr' => '10.141.8.180:6789/0',
        'name' => 'ceph001',
        'up'   => 1,
        'rank' => 1
    },
    'ceph002b' => {
        'addr' => '10.141.8.181:6754/0',
        'name' => 'ceph002b',
        'up'   => 1,
        'rank' => 0
    },
    'ceph003' => {
        'addr' => '10.141.8.182:6789/0',
        'name' => 'ceph003',
        'up'   => '',
        'rank' => 2
    }
);

Readonly::Hash our %OSDS => ( 
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
    'ceph001'   => {
        'gid'   => 5047,
        'name'  => 'ceph001',
        'up'    => 1
   }
);
Readonly::Array our @DELMON => (
    ['mon',
    'destroy',
    'ceph002b']
);

Readonly::Array our @ADDOSD => (
 [
   'osd',
   'prepare',
   'ceph002.cubone.os:/var/lib/ceph/osd/sdc:/var/lib/ceph/log/sda4/osd-sdc/journal'
 ],
 [
   'osd',
   'activate',
   'ceph002.cubone.os:/var/lib/ceph/osd/sdc:/var/lib/ceph/log/sda4/osd-sdc/journal'
 ]);

Readonly::Array our @ADDMON => (
    ['mon',
    'create',
    'ceph002.cubone.os']
);
Readonly::Array our @ADDMDS => (
    ['mds',
    'create',
    'ceph002.cubone.os']
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

Readonly our $STATE => '{"election_epoch":34,"quorum":[0,1],"quorum_names":["ceph001","ceph002b"],"quorum_leader_name":"ceph002b","monmap":{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002b","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}]}}';
