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

Readonly::Array our @DELMON => (
    ['mon',
    'destroy',
    'ceph002b']
);

Readonly::Array our @ADDMON => (
    ['mon',
    'create',
    'ceph002']
);
Readonly::Array our @NEWCLUS => (
   [
     '/usr/bin/ceph-deploy',
     'new',
     'ceph001',
     'ceph002',
     'ceph003'
   ],
   [
     '/usr/bin/ceph-deploy',
     'mon',
     'create-initial'
   ],
);

Readonly our $STATE => '{"election_epoch":34,"quorum":[0,1],"quorum_names":["ceph001","ceph002b"],"quorum_leader_name":"ceph002b","monmap":{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002b","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}]}}';
