NCM-ceph
========

## Implemented features

Features that are implemented at this moment:

* Creating cluster (manual step involved)
* Set admin hosts and push config
* Checking/adding/removing Monitors
* Checking/adding/removing OSDs
* Checking/adding/removing MDSs
* Building up/changing a crushmap

The implementation keeps safety as top priority. Therefore:

* The config of MON, OSD and MDSs are first checked completely. Only if no errors were found, the actual changes will be deployed.
* No removals of MONs, OSDs or MDSs are actually done at this moment. Instead of removing itself, it prints the commands to use.
* Backup files are always made of the configfiles and decompiled crushmap files. 
These timestamped files can be found in the 'ncm-ceph' folder in the home directory of the ceph user
* When something is not right and returns an error, the whole component exits.
* You can set the version of ceph and ceph-deploy in the Quattor scheme. The component will then only run if the versions of ceph and ceph-deploy match with those versions.

## How to run component

* The schema details are annotated in the schema file. 
* Example pan files are included in the examples folder and also in the test folders.
* For details on doing the initial run of the component, look at the component man page.

# Dependencies

The component is tested with Ceph version 0.72.2 and Ceph-Deploy version 1.3.5. 

Following package dependencies should be installed to run the component:

* perl-Data-Structure-Util 
* perl-Config-Tiny 
* perl-Test-Deep
* perl-Data-Compare >= 1.23 !

This version of Data-Compare can be found on [http://www.city-fan.org/ftp/contrib/perl-modules/]

Attention: Some repositories (e.g. rpmforge) are shipping some versions like 1.2101 and 1.2102.

Other things needed before using the component:

* A ceph user is needed on all the hosts.
* The deployhost(s) should have passwordless ssh access to all the hosts of the cluster
  - e.g. by distributing the public key(s) of the ceph-deploy host(s) over the cluster hosts
    (As described in the ceph-deploy documentation: 
      http://ceph.com/docs/master/start/quick-start-preflight/)

# Points that need attention/improvement

* There is not yet a controlled restart of the daemons if changes are commited that requires daemon restart
* ceph-deploy removal osd command is not yet implemented (by ceph-deploy itself)
* If some host of the defined cluster is down, the whole component is unable to run.
* Default pg-num and pgp-num not respected by ceph-deploy. Pools still need manual intervention at that point:

  `ceph osd pool set {pool-name} pg_num {pg_num}`

  `ceph osd pool set {pool-name} pgp_num {pg_num}`
* Scalabilty issues: at this point the ssh connections are per osd instead of per host.
* Ceph-disk is not enforced. You have to make sure that the filesystems are created with recommended tuning (see examples)

# Future features

* Finer configuration control (Per-osd/host base)
* Pool support
* Firefly support?
* Wildcard support in version numbers
