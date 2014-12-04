### NAME

The _cdp_ component manages the configuration file
`/etc/cdp-listend.conf.`

### DESCRIPTION

The _cdp_ component manages the configuration file for the
cdp-listend daemon.

### RESOURCES

- `configfile : string`

    The location of the configuration file.  Normally this should not be
    changed.  Defaults to `/etc/cdp-listend.conf`

- `port ? type_port`

    The port used by the daemon.  

- `nch ? string`

    The binary to execute when receiving a CDB update packet.

- `nch_smear ? long(0..)`

    The range of time delay for executing the nch executable.  The
    execution will be delayed by \[0, nch\_smear\] seconds.

- `fetch ? string`

    The binary to execute when receiving a CCM update packet.

- `fetch_offset ? long(0..)`

    Fetch execution offset.

    See explanation for `fetch_smear`.

- `fetch_smear ? long(0..)`

    Fetch time smearing.

    The fetch binary will be started at a point in time between
    `fetch_offset` and `fetch_offset + fetch_smear` seconds
    after receiving a notification packet.

    The range of time delay for executing the fetch executable.  The
    execution will be delayed by \[0, fetch\_smear\] seconds.

### EXAMPLES

    "/software/components/cdp/fetch" = "/usr/sbin/ccm-fetch";
    "/software/components/cdp/fetch_smear" = 30;
