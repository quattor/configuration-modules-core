### DESCRIPTION

This component configures the nagios/icinga addon, pnp4nagios

### FILES

This component touches the following files: 
`/etc/pnp4nagios/npcd.cfg`
/etc/pnp4nagios/config.php
`/etc/pnp4nagios/nagios.cfg`
/etc/pnp4nagios/process\_perfdata.cfg

### STRUCTURE

These are the top-level fields provided by the component. For
information on any of these fields' structure, please look pnp4nagios
documentation. 

- `/software/components/pnp4nagios/npcd`

    Named list of npcd configuration options.

- `/software/components/pnp4nagios/php`

    Named list of php configuration options.

- `/software/components/pnp4nagios/nagios`

    Named list of nagios configuration options.

- `/software/components/pnp4nagios/perfata`

    Named list of perfdata configuration options.
