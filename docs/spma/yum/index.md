---
layout: documentation
title: spma / yum
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

NCM::Component::spma::yum - NCM SPMA configuration component for Yum

### SYNOPSIS

This document describes how to control the behaviour of the package
manager itself.  For information on how to manage packages with
Quattor, please check
[http://quattor.org/documentation/2013/04/05/package-management.html](http://quattor.org/documentation/2013/04/05/package-management.html).

### RESOURCES

- `/software/components/spma/active` : boolean

    activates/deactivates the component.

- `/software/components/spma/unescape` : boolean

    if defined and set to false, then it is assumed that the package information in
    the profile has not been escaped with PAN's escape() function. This setting is
    only meaningful when using a tool different than PAN for generating CDB
    profiles.

    Currently ignored.

- `/software/components/spma/tmpdir` : string

    If defined, set the path to the temporary directory (for compatibility
    with -bad- packages that need to remove the sticky bit from `/tmp`)

#### Flags for Yum processing:

- `/software/components/spma/process`\_obsoletes : boolean

    Make Yum replace obsoleted packages by their recommended counterparts.
    Defaults to `false` to keep backwards compatibility.

- `/software/components/spma/userpkgs` : string ("yes|no")

    Whether SPMA should keep any packages the user may have installed
    manually.

    Set to `no` to make the SPMA take full control of all your software
    installations.  Set to `yes` to preserve any packages you installed
    by hand.  If you do so, SPMA will never remove a package.

- `/software/components/spma/userpkgs`\_retry : boolean

    Yum-based spma might get confused and fails when it tries 
    to remove packages when `userpkgs` is `no` while installing 
    new ones. Typically it will (try to) remove a 
    leaf package, that is also to be installed as a dependency of a new 
    to-be-installed package.

    With `userpkgs_retry` set to `true`, the package update process 
    will be retried in case of failure in 2 steps, a first retry while 
    preserving the installed packages, and if this retry was succesful, 
    followed by a second retry where it will (try to) remove leaf packages 
    again.

- `/software/components/spma/userprio` : string ("yes|no")

    Obsoleted and ignored.

- `/software/components/spma/protectkernel` : string ("yes|no")

    Obsolete and ignored.  This is delegated to Yum.

- `/software/components/spma/packager` : string

    Must contain `yum` to use this module.

- `/software/components/spma/usespmlist` : string ("yes|no")

    Obsolete.  Currently ignored.

- `/software/components/spma/rpmexclusive`: string ("yes|no")

    Obsolete.  Currently ignored.

- `/software/components/spma/debug`: string ("0|1|2|3|4|5")

    Obsolete.  Currently ignored.

- `/software/components/spma/verbose`: string ("0|1")

    Obsolete.  Currently ignored.

- `/software/components/spma/cachedir`: string

    Obsolete.  Currently ignored.

- `/software/components/spma/localcache`: string ("yes|no")

    Obsolete.  Currently ignored.

- `/software/components/spma/proxy`: string ("yes|no")

    Whether to use a proxy.

- `/software/components/spma/proxytype`: string ("forward|reverse")

    Type of proxy (reverse or forward).

- `/software/components/spma/proxyhost`: string

    Comma-separated list of proxy hosts.  If you have a forward proxy you
    should specify only one.  You may specify several reverse proxies
    here, and they will be appended to the `baseurl` entry of each
    repository's configuration.

- `/software/components/spma/proxyport`: string

    Port where the proxies are listening.

- `/software/components/spma/run`: string ("yes|no")

    Whether to actually run Yum operations that may install, remove or
    update packages.

- `/software/components/spma/headnode`: boolean

    Ignored.

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none. However, since the SPMA is typically used for updating components
in RPM/PKG format, it is convenient to run the SPMA component before any
other.

### FILES

`/etc/spma.conf`, `/var/lib/spma-target.cf`.

### NOTES

This component honors the __\--noaction__ mode.

### BUGS

The typing of the CDB entries is yet to be done: for now, all of them are
strings.

Original author: German Cancio <German.C>

Author of the Yum-based package manager: Luis Fernando Muñoz Mejías

### SEE ALSO

You must read this document to understand how to manage packages
with Quattor:

[http://quattor.org/documentation/2013/04/05/package-management.html](http://quattor.org/documentation/2013/04/05/package-management.html),

These links detail experiences and strategies relevant for managing
software installations in large sites:

[http://quattor.org/documentation/2013/02/07/yum-package-management.html](http://quattor.org/documentation/2013/02/07/yum-package-management.html),
[http://quattor.org/documentation/2013/01/29/spma-yum-upgrade.html](http://quattor.org/documentation/2013/01/29/spma-yum-upgrade.html)
[http://quattor.org/blog/2013/01/29/package-layout-proposal.html](http://quattor.org/blog/2013/01/29/package-layout-proposal.html)
[http://quattor.org/blog/2013/03/27/cleaning-up-packages.html](http://quattor.org/blog/2013/03/27/cleaning-up-packages.html)
