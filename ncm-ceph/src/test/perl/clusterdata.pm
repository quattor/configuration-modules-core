package clusterdata;

use strict;
use warnings;

use Readonly;

Readonly our $CEPH_VERSION => 'ceph version 12.2.2 (cf0baeeeeba3b47f9427c6c97e2144b094b7e5ba) luminous (stable)';
Readonly our $CEPH_VERSION_OCT => 'ceph version 15.2.8 (bdf3eebcd22d7d0b3dd4d5501bee5bac354d5b55) octopus (stable)';

Readonly our $STATE => '{"election_epoch":34,"quorum":[0,1],"quorum_names":["ceph001","ceph002"],"quorum_leader_name":"ceph002","monmap":{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}]}}';
