---
layout: documentation
title: ceph
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

ncm-ceph: Configuration module for CEPH

### DESCRIPTION

Configuration module for CEPH

### IMPLEMENTED FEATURES

Features that are implemented at this moment:

- Creating cluster (manual step involved)
- Set admin hosts and push config
- Checking/adding/removing Monitors
- Checking/adding/removing OSDs
- Checking/adding/removing MDSs
- Building up/changing a crushmap

The implementation keeps safety as top priority. Therefore:

- The config of MON, OSD and MDSs are first checked completely. Only if no errors were found, the actual changes will be deployed.
- No removals of MONs, OSDs or MDSs are actually done at this moment. Instead of removing itself, it prints the commands to use. 
- Backup files are always made of the configfiles and decompiled crushmap files. These timestamped files can be found in the 'ncm-ceph' folder in the home directory of the ceph user
- When something is not right and returns an error, the whole component exits.
- You can set the version of ceph and ceph-deploy in the Quattor scheme. The component will then only run if the versions of ceph and ceph-deploy match with those versions.

### INITIAL CREATION

\- The schema details are annotated in the schema file. 

\- Example pan files are included in the examples folder and also in the test folders.

To set up the initial cluster, some steps should be taken:

1. First create a ceph user on all the hosts.
2. The deployhost(s) should have passwordless ssh access to all the hosts of the cluster
        e.g. by distributing the public key(s) of the ceph-deploy host(s) over the cluster hosts
            (As described in the ceph-deploy documentation: 
                        http://ceph.com/docs/master/start/quick-start-preflight/)
3. Run the component a first time. 
            It shall fail, but you should get the initial command for your cluster
4. Run this command
5. Run the component again to start the configuration of the new cluster

### RESOURCES

#### `/software/components/ceph`

The configuration information for the component.  Each field should
be described in this section. 

### DEPENDENCIES

The component is tested with Ceph version 0.80 and ceph-deploy version 1.5.1. 

Following package dependencies should be installed to run the component:

- perl-Data-Structure-Util 
- perl-Config-Tiny 
- perl-Test-Deep
- perl-Data-Compare >= 1.23 !
- perl-Git-Repository

This version of Data-Compare can be found on http://www.city-fan.org/ftp/contrib/perl-modules/

Attention: Some repositories (e.g. rpmforge) are shipping some versions like 1.2101 and 1.2102.


