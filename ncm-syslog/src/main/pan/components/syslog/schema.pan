# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/syslog/schema;

include quattor/schema;

type component_selector_type = {
    "facility"      : string with match (self,'\*|auth|authpriv|cron|daemon|kern|lpr|mail|mark|news|security|syslog|user|uucp|local[0-7]')
    "priority"      : string with match (self,'\*|debug|info|notice|none|warning|warn|err|error|crit|alert|emerg|panic')
};

type component_syslog_type = {
    "selector"       ? component_selector_type[]
    "action"         : string
    "template"	     ? string
    "comment"        ? string
};

type component_syslog_entries = {
    include structure_component
    "config"         : component_syslog_type[]
    "directives"     ? string[]
    "daemontype"     ? string with match (self,'syslog|rsyslog')
    "file"	     ? string
    "syslogdoptions" ? string
    "klogdoptions"   ? string
    "fullcontrol"    ? boolean
};

type "/software/components/syslog" = component_syslog_entries;
