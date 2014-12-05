### DESCRIPTION

This component configures syslog-ng, an alternative logging facility
to Scientific Linux' sysklogd. If you want to configure sysklogd, use
ncm-syslog instead of this component.

The component's structure matches rather closely syslog-ng.conf file format.

### STRUCTURE

These are the top-level fields provided by the component. For
information on any of these fields' structure, please look syslog-ng's
documentation. Options accepting ony "yes" and "no" are mapped to Pan
booleans.

- `/software/components/syslogng/sources` : source{}

    Named list of `source` structures, indexed by `source` name.

- `/software/components/syslogng/destinations` : destination{}

    Named list of `destination` structures, indexed by `destination`
    name.

- `/software/components/syslogng/filters` ? filter{}

    Named list of `filter` structures, indexed by `filter` name. Rules
    inside a filter are combined by an OR operator. If you want AND
    filters, use several filters inside a log path.

    An additional field to the standard syslog-ng's usual filter
    capabilities is added: `exclude_filters`. This links to an already
    defined filter, but it will be included in current one, NEGATED.

- `/software/components/syslogng/log`\_rules : log\_rule\[\]

    List of `log_rule` structures.

#### Defining a log path

Log paths are defined on
`/software/components/syslogng/log_rules`. Their structure is as
follows:

- sources : string\[\]

    List of sources on this path. Each member of this list is a source
    name, and must exist on `/software/components/syslogng/sources`.

- destinations : string\[\]

    List of destinations on this path. Each member of this list must exist
    on `/software/components/syslogng/destinations`.

- filters ? string\[\]

    List of filters to be applied on this path. Each member of this list
    must exist on `/software/components/syslogng/destinations`.

- flags ? flag\_structure

    Flags to be applied on this log rule.

### SEE ALSO

http://www.balabit.com/dl/html/syslog-ng-admin-guide\_en.html/bk01-toc.html,
[syslog-ng(8)](http://man.he.net/man8/syslog-ng) [syslog-ng.conf(5)](http://man.he.net/man5/syslog-ng.conf)
