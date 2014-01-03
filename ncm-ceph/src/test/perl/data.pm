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

Readonly our $STATE => '{"election_epoch":34,"quorum":[0,1],"quorum_names":["ceph001","ceph002b"],"quorum_leader_name":"ceph002b","monmap":{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002b","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}]}}';
