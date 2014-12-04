### NAME

The _ccm_ component manages the configuration file
for CCM.

### DESCRIPTION

The _ccm_ component manages the configuration file for the CCM
daemon.  This is usually the `/etc/ccm.conf` file. See the ccm-fetch
manpage for more details.

### RESOURCES

- `configFile : string`

    The location of the configuration file.  Normally this should not be
    changed. Defaults to `/etc/ccm.conf`.

- `profile : type_hostURI`

    The URL for the machine's profile.  You can use either the http or
    https protocols (the file protocol is also possible eg. for tests).
    (see ccm-fetch manpage)

- `profile_failover ? type_hostURI`

    profile failover URL in case the above is not working (see ccm-fetch manpage)

- `context ? type_hostURI`

    Unsupported. May be removed in a future release.

- `debug : long(0..1)`

    Turn on debugging.  Takes either 0 or 1.  Defaults to 0.

- `force : long(0..1)`

    Force fetching of the machine profile.  Turning this on ignores the
    modification times.  Takes either 0 or 1.  Defaults to 0.

- `preprocessor ? string`

    Preprocessor executable which combines the profile and context.
    Currently not used.

- `cache_root : string`

    The root directory of the CCM cache.  Defaults to `/var/lib/ccm`.

- `get_timeout : long(0..)`

    The timeout for the download operation in seconds.  Defaults to 30.

- `lock_retries : long(0..)`

    Number of times to try to get the lock on the cache.  Defaults to 3.

- `lock_wait : long(0..)`

    Number of seconds to wait between attempts to acquire the lock.  Defaults to 30.

- `retrieve_retries : long(0..)`

    Number of times to try to get the context from the server.  Defaults to 3.

- `retrieve_wait : long(0..)`

    Number of seconds to wait between attempts to get the context from the
    server.  Defaults to 30.

- `cert_file ? string`

    The certificate file to use for an https protocol.

- `key_file ? string`

    The key file to use for an https protocol.

- `ca_file ? string`

    The CA file to use for an https protocol.

- `ca_dir ? string`

    The directory containing accepted CA certificates when using the https
    protocol.

- `world_readable : long(0..1)`

    Whether the profiles should be world-readable.  This takes either a 0
    or 1.  Defaults to 0.

- `base_url ? type_absoluteURI`

    If `profile` is not a URL, a profile url will be calculated from
    `base_url` and the local hostname.

- `dbformat ? string`

    Format of the local database, must be `DB_File`, `CDB_File` or `GDBM_File`.
    If not specified, the component will default to `GDBM_File`.
