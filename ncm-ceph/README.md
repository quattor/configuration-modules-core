NCM-ceph
========

## Component documentation


* Documentation of the CEPH component can be found in the component man page, or in the online quattor documentation.
* The schema details are annotated in the schema file.
* Example pan files are included in the template-library-examples repository (https://github.com/quattor/template-library-examples)
and also in the test folders.

## Upgrade instructions from Jewel to Luminous

* Jewel can only be used with v1 of the schema, Luminous only with v2
* First upgrade the ceph daemons to Luminous following every step of http://docs.ceph.com/docs/master/release-notes/#upgrade-from-jewel-or-kraken
* Disable the component (eg. noquattor)
* If ncm-ceph v1 crushmap labels were used, alter the crushmap to use classes (https://ceph.com/community/new-luminous-crush-device-classes/) 
* Build the new templates for the cluster using v2 of the schema (see pan example templates)

To replace OSD servers with bluestore OSDs:
* Copy bootstrap-osd key for ncm-download 

Do for each OSDServer (If deployhosts is osd server, start with this one)
* remove osds from a server
    ceph osd out $osdid; ( Wait for rebalance)
    systemctl stop ceph-osd.target;
    ceph osd crush remove osd.$osdid; ceph auth del osd.$osdid; ceph osd rm $osdid
* zap the disks: sgdisk -Z
* reinstall the host using the newly build profile
* The OSDS will be created on reinstall of the host
