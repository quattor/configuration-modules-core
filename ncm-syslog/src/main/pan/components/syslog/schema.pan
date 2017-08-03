${componentschema}

include 'quattor/types/component';

type component_syslog_selector_type = {
    "facility" : string with match(SELF,
        '^(?:(\*|auth|authpriv|cron|daemon|kern|lpr|mail|mark|news|security|syslog|user|uucp|local[0-7])(,|$))+$'
    )
    "priority" : string with match(SELF,
        '^(\*|debug|info|notice|none|warning|warn|err|error|crit|alert|emerg|panic)$'
    )
};

type component_syslog_legacy_rule = {
    "selector" ? component_syslog_selector_type[]
    "action" : string
    "template" ? string with {deprecated(0, 'syslog/config template is ignored'); true}
    "comment" ? string # only for fullcontrol, wrapped in ^\n# .. \n$ if needed
};

type ${project.artifactId}_component = {
    include structure_component
    "config" : component_syslog_legacy_rule[]
    "directives" ? string[]
    "daemontype" : string = 'syslog' with match (SELF, '^(syslog|rsyslog)$')
    @{Configuration filename. Defaults to /etc/<daemontype>.conf.}
    "file" ? string
    @{Options for syslogd /etc/sysconfig/(r)syslog (will be wrapped in double quotes if needed)}
    "syslogdoptions" ? string
    @{Options for the klogd /etc/sysconfig/(r)syslog (will be wrapped in double quotes if needed)}
    "klogdoptions" ? string
    @{Determines whether component has full control over the configuration file,
      eventually erasing entries from other sources. If false or not defined, entries
      from other sources are kept and configuration entries are added.}
    "fullcontrol" ? boolean
};
