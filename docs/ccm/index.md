---
layout: documentation
title: ccm
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

The _ccm_ component manages the configuration file
for CCM.

### DESCRIPTION

The _ccm_ component manages the configuration file for the CCM
daemon.  This is usually the `/etc/ccm.conf` file. See the ccm-fetch
manpage for more details.

### RESOURCES

#### configFile (/etc/ccm.conf)

The location of the configuration file.  Normally this should not be
changed.

#### 

#### profile

The URL for the machine's profile.  You can use either the http or
https protocols (the file protocol is also possible eg. for tests).
(see ccm-fetch manpage)

#### profile\_failover

profile failover URL in case the above is not working (see ccm-fetch manpage)

#### debug

Turn on debugging.  Takes either 0 or 1.

#### force

Force fetching of the machine profile.  Turning this on ignores the
modification times.  Takes either 0 or 1.

#### preprocessor

Preprocessor executable which combines the profile and context.
Currently not used.

#### cache\_root

The root directory of the CCM cache.  Defaults to `/var/lib/ccm.`

#### get\_timeout

The timeout for the download operation in seconds.

#### lock\_retries

Number of times to try to get the lock on the cache.

#### lock\_wait

Number of seconds to wait between attempts to acquire the lock.

#### retrieve\_retries

Number of times to try to get the context from the server.

#### retrieve\_wait

Number of seconds to wait between attempts to get the context from the
server.

#### cert\_file

The certificate file to use for an https protocol.

#### key\_file

The key file to use for an https protocol.

#### ca\_file

The CA file to use for an https protocol.

#### ca\_dir

The directory containing accepted CA certificates when using the https
protocol.

#### world\_readable

Whether the profiles should be world-readable.  This takes either a 0
or 1.
