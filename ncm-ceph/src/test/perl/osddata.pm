package osddata;

use strict;
use warnings;

use Readonly;

Readonly our $BOOTSTRAP_OSD_KEYRING => '/var/lib/ceph/bootstrap-osd/ceph.keyring';
Readonly our $BOOTSTRAP_OSD_KEYRING_SL => '/etc/ceph/ceph.client.bootstrap-osd.keyring';
Readonly our $GET_CEPH_PVS_CMD => 'pvs -o pv_name,lv_tags --no-headings --reportformat json';

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

Readonly our $OSD_VOLUME_CREATE => 'ceph-volume lvm create --bluestore --data /dev';
