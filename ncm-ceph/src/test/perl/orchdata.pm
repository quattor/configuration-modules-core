package orchdata;

use strict;
use warnings;

use Readonly;

Readonly our $HOSTS_JSON => '[{"addr": "mds2801.banette.os", "hostname": "mds2801.banette.os", "labels": ["mon", "mds", "mgr"], "status": ""}, {"addr": "mds2802.banette.os", "hostname": "mds2802.banette.os", "labels": ["mon", "mds", "mgr"], "status": ""}]';

Readonly our $MON_YAML => <<EOD;
---
placement:
  hosts:
  - cephmon1.test.nw
  - cephmon2.test.nw
  - cephmon3.test.nw
service_type: mon
EOD

Readonly our $MGR_YAML => <<EOD;
---
placement:
  count: 3
  label: mgr
service_type: mgr
EOD

Readonly our $MDS_YAML => <<EOD;
---
placement:
  label: mds
service_id: cephfs
service_type: mds
EOD

Readonly our $OSD_YAML => <<EOD;
---
data_devices:
  rotational: 0
encrypted: true
placement:
  host_pattern: fastnode*
service_id: nvme_drives
service_type: osd
---
data_devices:
  all: true
encrypted: true
placement:
  host_pattern: '*'
service_id: default_drive_group
service_type: osd
EOD

Readonly our $HOSTS_YAML => <<EOD;
---
addr: cephmon1.test.nw
hostname: cephmon1.test.nw
labels:
- mon
- mds
- mgr
service_type: host
---
addr: cephmon2.test.nw
hostname: cephmon2.test.nw
labels:
- mon
- mds
- mgr
service_type: host
---
addr: cephmon3.test.nw
hostname: cephmon3.test.nw
labels:
- mon
- mds
- mgr
service_type: host
---
hostname: cephosd1.test.nw
service_type: host
---
hostname: cephosd2.test.nw
service_type: host
EOD

1;

