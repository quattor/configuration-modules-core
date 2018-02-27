package osddata;

use strict;
use warnings;

use Readonly;

Readonly our $BOOTSTRAP_OSD_KEYRING => '/var/lib/ceph/bootstrap-osd/ceph.keyring';
Readonly our $BOOTSTRAP_OSD_KEYRING_SL => '/etc/ceph/ceph.client.bootstrap-osd.keyring';
Readonly our $GET_CEPH_PVS_CMD => 'pvs -o pv_name,lv_tags --no-headings --reportformat json';
Readonly our $CRUSH => '/usr/bin/ceph -f json osd crush';

Readonly our $OSD_PVS_OUT => <<EOD;
  {
      "report": [
          {
              "pv": [
                  {"pv_name":"/dev/sda4", "lv_tags":""},
                  {"pv_name":"/dev/sda4", "lv_tags":""},
                  {"pv_name":"/dev/sdb", "lv_tags":"ceph.block_device=/dev/ceph-2bca40e6-dbdc-4c8b-a53a-a291d269a0fc/osd-block-ef17d9e3-c47d-4b72-a7a0-fe9ec71c352d,ceph.block_uuid=PrHl0o-y4C4-lIn0-FOKz-YCvm-ZMi9-X061Og,ceph.cluster_fsid=d3da1b0d-60a1-41bc-adb1-7df8191c16a7,ceph.cluster_name=ceph,ceph.osd_fsid=ef17d9e3-c47d-4b72-a7a0-fe9ec71c352d,ceph.osd_id=27,ceph.type=block"},
                  {"pv_name":"/dev/sdd", "lv_tags":"ceph.block_device=/dev/ceph-d3da1b0d-60a1-41bc-adb1-7df8191c16a7/osd-block-681e05db-d5c4-4a71-82ee-be827d1f031a,ceph.block_uuid=cR3maW-cXhY-H7j0-oNbQ-oQDT-1kG4-fjsoTu,ceph.cluster_fsid=d3da1b0d-60a1-41bc-adb1-7df8191c16a7,ceph.cluster_name=ceph,ceph.osd_fsid=681e05db-d5c4-4a71-82ee-be827d1f031a,ceph.osd_id=24,ceph.type=block"}
              ]
          }
      ]
  }
EOD

Readonly our $OSD_PVS_OUT_ALT => <<EOD;
  {
      "report": [
          {
              "pv": [
                  {"pv_name":"/dev/sda4", "lv_tags":""},
                  {"pv_name":"/dev/sda4", "lv_tags":""},
                  {"pv_name":"/dev/sdb", "lv_tags":"ceph.block_device=/dev/ceph-2bca40e6-dbdc-4c8b-a53a-a291d269a0fc/osd-block-ef17d9e3-c47d-4b72-a7a0-fe9ec71c352d,ceph.block_uuid=PrHl0o-y4C4-lIn0-FOKz-YCvm-ZMi9-X061Og,ceph.cluster_fsid=d3da1b0d-60a1-41bc-adb1-7df8191c16a7,ceph.cluster_name=ceph,ceph.osd_fsid=AAAAAFOUTef17d9e3-c47d-4b72-a7a0-fe9ec71c352d,ceph.osd_id=27,ceph.type=block"},
                  {"pv_name":"/dev/sdd", "lv_tags":"ceph.block_device=/dev/ceph-d3da1b0d-60a1-41bc-adb1-7df8191c16a7/osd-block-681e05db-d5c4-4a71-82ee-be827d1f031a,ceph.block_uuid=cR3maW-cXhY-H7j0-oNbQ-oQDT-1kG4-fjsoTu,ceph.cluster_fsid=d3da1b0d-60a1-41bc-adb1-7df8191c16a7,ceph.cluster_name=ceph,ceph.osd_fsid=681e05db-d5c4-4a71-82ee-be827d1f031a,ceph.osd_id=24,ceph.type=block"}
              ]
          }
      ]
  }
EOD


Readonly our %OSD_DEPLOYED => (
   sdb => {
     id => '27',
     uuid => 'ef17d9e3-c47d-4b72-a7a0-fe9ec71c352d'
   },
   sdd => {
     id => '24',
     uuid => '681e05db-d5c4-4a71-82ee-be827d1f031a'
   }
);

Readonly our $OSD_VOLUME_CREATE => 'ceph-volume lvm create --data /dev';

Readonly our $OSD_DUMP => <<EOD;
  {
    "epoch": 643,
    "fsid": "82766e04-585b-49a6-a0ac-c13d9ffd0a7d",
    "created": "2018-01-19 11:42:53.122869",
    "modified": "2018-02-08 16:18:50.489055",
    "flags": "sortbitwise,recovery_deletes,purged_snapdirs",
    "crush_version": 105,
    "full_ratio": 0.950000,
    "backfillfull_ratio": 0.900000,
    "nearfull_ratio": 0.850000,
    "cluster_snapshot": "",
    "pool_max": 4,
    "max_osd": 44,
    "require_min_compat_client": "hammer",
    "min_compat_client": "hammer",
    "require_osd_release": "luminous",
    "osds": [
        {
            "osd": 0,
            "uuid": "1a65959a-6951-4e01-a005-f5600601f424",
            "up": 1,
            "in": 1,
            "weight": 1.000000,
            "primary_affinity": 1.000000,
            "last_clean_begin": 229,
            "last_clean_end": 601,
            "up_from": 620,
            "up_thru": 620,
            "down_at": 602,
            "lost_at": 0,
            "public_addr": "10.141.8.180:6805/2955",
            "cluster_addr": "10.141.8.180:6806/2955",
            "heartbeat_back_addr": "10.141.8.180:6807/2955",
            "heartbeat_front_addr": "10.141.8.180:6808/2955",
            "state": [
                "exists",
                "up"
            ]
        },
        {
            "osd": 24,
            "uuid": "681e05db-d5c4-4a71-82ee-be827d1f031a",
            "up": 1,
            "in": 1,
            "weight": 1.000000,
            "primary_affinity": 1.000000,
            "last_clean_begin": 228,
            "last_clean_end": 601,
            "up_from": 620,
            "up_thru": 620,
            "down_at": 602,
            "lost_at": 0,
            "public_addr": "10.141.8.180:6849/2979",
            "cluster_addr": "10.141.8.180:6850/2979",
            "heartbeat_back_addr": "10.141.8.180:6851/2979",
            "heartbeat_front_addr": "10.141.8.180:6852/2979",
            "state": [
                "exists",
                "up"
            ]
        },
        {
            "osd": 27,
            "uuid": "ef17d9e3-c47d-4b72-a7a0-fe9ec71c352d",
            "up": 0,
            "in": 0,
            "weight": 0.000000,
            "primary_affinity": 1.000000,
            "last_clean_begin": 231,
            "last_clean_end": 602,
            "up_from": 622,
            "up_thru": 622,
            "down_at": 628,
            "lost_at": 0,
            "public_addr": "10.141.8.180:6801/2901",
            "cluster_addr": "10.141.8.180:6802/2901",
            "heartbeat_back_addr": "10.141.8.180:6803/2901",
            "heartbeat_front_addr": "10.141.8.180:6804/2901",
            "state": [
                "autoout",
                "exists"
            ]
        },
        {
            "osd": 3,
            "uuid": "35875388-e954-4060-9dfb-08ceb6d26708",
            "up": 1,
            "in": 1,
            "weight": 1.000000,
            "primary_affinity": 1.000000,
            "last_clean_begin": 232,
            "last_clean_end": 602,
            "up_from": 623,
            "up_thru": 623,
            "down_at": 603,
            "lost_at": 0,
            "public_addr": "10.141.8.180:6831/2975",
            "cluster_addr": "10.141.8.180:6833/2975",
            "heartbeat_back_addr": "10.141.8.180:6835/2975",
            "heartbeat_front_addr": "10.141.8.180:6836/2975",
            "state": [
                "exists",
                "up"
            ]
        }
    ]
  }
EOD

