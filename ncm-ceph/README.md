NCM-ceph
========

## Component documentation


* Documentation of the CEPH component can be found in the component man page, or in the online quattor documentation.
* The schema details are annotated in the schema file.
* Example pan files are included in the template-library-examples repository (https://github.com/quattor/template-library-examples)
and also in the test folders.

# Points that need attention/improvement

* There is not yet a controlled restart of the daemons if changes are commited that requires daemon restart
* ceph-deploy removal osd command is not yet implemented (by ceph-deploy itself)
* If some host of the defined cluster is down, the whole component is unable to run.
* Default pg-num and pgp-num not respected by ceph-deploy. Pools still need manual intervention at that point:

  `ceph osd pool set {pool-name} pg_num {pg_num}`

  `ceph osd pool set {pool-name} pgp_num {pg_num}`
* Ceph-disk is not enforced. You have to make sure that the filesystems are created with recommended tuning (see examples)

# Future features

* Pool support
* Ceph auth
