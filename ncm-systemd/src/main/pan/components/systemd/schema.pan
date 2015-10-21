# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/schema;

include 'quattor/types/component';
include 'components/accounts/functions';

# TODO: some generic types, candidates for template-library-core
@documentation{
    hwloc location, e.g. node:1 for NUMAnode 1
}
type hwloc_location = string with match(SELF, '^[\w:.]+$');

@documentation{
    syslog facility to use when logging to syslog
}
type syslog_facility = string with match(SELF, '^(kern|user|mail|daemon|auth|syslog|lpr|news|uucp|cron|authpriv|ftp|local[0-7])$');

@documentation{
    syslog level to use when logging to syslog or the kernel log buffer
}
type syslog_level = string with match(SELF, '^(emerg|alert|crit|err|warning|notice|info|debug)$');

type ${project.artifactId}_skip = {
    "service" : boolean = false
};

# TODO: make this more finegrained, e.g. has to be existing unit; or check types
type ${project.artifactId}_valid_unit = string;

# adding new ones
# go to http://www.freedesktop.org/software/systemd/man/systemd.directives.html
# and follow the link to the manual

@documentation{
the [Unit] section
http://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BUnit%5D%20Section%20Options
}
type ${project.artifactId}_unitfile_config_unit = {
    'After' ? ${project.artifactId}_valid_unit[]
    @{start with empty string to reset previously defined paths}
    'AssertPathExists' ? string[]
    'Description' ? string
    'Requires' ? ${project.artifactId}_valid_unit[]
};

@documentation{
the [Install] section
http://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BInstall%5D%20Section%20Options
}
type ${project.artifactId}_unitfile_config_install = {
    'WantedBy' ? ${project.artifactId}_valid_unit[]
};

type ${project.artifactId}_unitfile_config_systemd_exec_stdouterr =  string with match(SELF, '^(inherit|null|tty|journal|syslog|kmsg|journal+console|syslog+console|kmsg+console|socket)$');


@documentation{
systemd.exec directives
http://www.freedesktop.org/software/systemd/man/systemd.exec.html
valid for [Service], [Socket], [Mount], or [Swap] sections
}
type ${project.artifactId}_unitfile_config_systemd_exec = {
    'Nice' ? long(-20..19)
    'PrivateTmp' ? boolean
    'WorkingDirectory' ? string
    'RootDirectory' ? string
    'User' ? defined_user
    'Group' ? defined_group
    'SupplementaryGroups' ? defined_group[]
    'OOMScoreAdjust' ? long(-1000..1000)
    'IOSchedulingClass' ? string with match(SELF, '^([0-3]|none|realtime|best-effort|idle)$')
    'IOSchedulingPriority' ? long(0..7) # 0 = highest
    'CPUSchedulingPolicy' ? string with match(SELF, '^(other|batch|idle|fifo|rr)$')
    'CPUSchedulingPriority' ? long(1..99) # 99 = highest
    'CPUSchedulingResetOnFork' ? boolean
    'CPUAffinity' ? long[][] # start with empty list to reset
    'UMask' ? string # octal notation, e.g. 0022
    'Environment' ? string{}[] # start with empty list
    'EnvironmentFile' ? string[] # overrides variables defined in Environment
    'StandardInput' ? string with match(SELF, '^(null|tty(-(force|fail))?|socket)$')
    'StandardOutput' ? ${project.artifactId}_unitfile_config_systemd_exec_stdouterr
    'StandardError' ? ${project.artifactId}_unitfile_config_systemd_exec_stdouterr
    'TTYPath' ? string
    'TTYReset' ? boolean
    'TTYVHangup' ? boolean
    'TTYVTDisallocate' ? boolean
    'SyslogIdentifier' ? string
    'SyslogFacility' ? syslog_facility
    'SyslogLevel' ? syslog_level
    'SyslogLevelPrefix' ? boolean
    'LimitAS' ? long(0..) # The maximum size of the process's virtual memory (address space) in bytes.
    'LimitCORE' ? long(0..) # Maximum size of a core file
    'LimitCPU' ? long(0..) # CPU time limit in seconds
    'LimitDATA' ? long(0..) # he maximum size of the process's data segment (initialized data, uninitialized data, and heap)
    'LimitFSIZE' ? long(0..) # The maximum size of files that the process may create
    'LimitLOCKS' ? long(0..) # (Early Linux 2.4 only) A limit on the number of locks
    'LimitMEMLOCK' ? long(0..) # The maximum number of bytes of memory that may be locked into RAM
    'LimitMSGQUEUE' ? long(0..) # pecifies the limit on the number of bytes that can be allocated for POSIX message queues for the real user ID of the calling process.
    'LimitNICE' ? long(0..40) # Specifies a ceiling to which the process's nice value can be raised. The actual ceiling for the nice value is calculated as 20 - rlim_cur.
    'LimitNOFILE' ? long(0..) # Specifies a value one greater than the maximum file descriptor number that can be opened by this process.
    'LimitNPROC' ? long(0..) # The maximum number of processes (or, more precisely on Linux, threads) that can be created for the real user ID of the calling process.
    'LimitRSS' ? long(0..) # Specifies the limit (in pages) of the process's resident set (the number of virtual pages resident in RAM).
    'LimitRTPRIO' ? long(0..) # Specifies a ceiling on the real-time priority that may be set for this process
    'LimitRTTIME' ? long(0..) # Specifies a limit (in microseconds) on the amount of CPU time that a process scheduled under a real-time scheduling policy may consume without making a blocking system call.
    'LimitSIGPENDING' ? long(0..) # Specifies the limit on the number of signals that may be queued for the real user ID of the calling process.
    'LimitSTACK' ? long(0..) # The maximum size of the process stack, in bytes.
};

@documentation{
the [Service] section
http://www.freedesktop.org/software/systemd/man/systemd.service.html
}
type ${project.artifactId}_unitfile_config_service = {
    include ${project.artifactId}_unitfile_config_systemd_exec
    'ExecStart' ? string
    'Type' ? string
};

@documentation{
Unit configuration sections
    includes, unit and install are type agnostic
        unit and install are mandatory, but not enforced by schema (possible issues in case of replace=true)
    the other attributes are only valid for a specific type
}
type ${project.artifactId}_unitfile_config = {
    @{list of existing/other units to base the configuration on
      (e.g. when creating a new service with a different name, based on an exsiting one)}
    'includes' ? string[]
    'install' ? ${project.artifactId}_unitfile_config_install
    'service' ? ${project.artifactId}_unitfile_config_service
    'unit' ? ${project.artifactId}_unitfile_config_unit
};

@documentation{
Custom unit configuration to allow inserting computed configuration data
It overrides the data defined in the regular config schema,
so do not forget to set those as well (can be dummy value).
}
type ${project.artifactId}_unitfile_custom = {
    @{CPUAffinity list determined via
      'hwloc-calc --physical-output --intersect PU <location0> <location1>'
      Allows to cpubind on numanodes (as we cannot trust logical CPU indices, which regular CPUAffinity requires)
      Forces an empty list to reset any possible previously defined affinity.}
    'CPUAffinity' ? hwloc_location[]
};

@documentation{
    Unit file configuration
}
type ${project.artifactId}_unitfile = {
    @{unitfile configuration data}
    "config" : ${project.artifactId}_unitfile_config
    @{custom unitfile configuration data}
    "custom" ? ${project.artifactId}_unitfile_custom
    @{replaceunitfile configuration: if true, only the defined parameters will be used by the unit; anything else is ignored}
    "replace" : boolean = false
    @{only use the unit parameters for unitfile configuration,
      ignore other defined here such as targets (but still allow e.g. values defined by legacy chkconfig)}
    "only" ? boolean
};

# legacy conversion
#   1 -> rescue
#   234 -> multi-user
#   5 -> graphical
# for now limit the targets
type ${project.artifactId}_target = string with match(SELF, "^(default|poweroff|rescue|multi-user|graphical|reboot)$");

type ${project.artifactId}_unit_type = {
    "name" ? string # shortnames are ok; fullnames require matching type
    "targets" : ${project.artifactId}_target[] = list("multi-user")
    "type" : string = 'service' with match(SELF, '^(service|target|sysv)$')
    "startstop" : boolean = true
    "state" : string = 'enabled' with match(SELF, '^(enabled|disabled|masked)$')
    @{unitfile configuration}
    "file" ? ${project.artifactId}_unitfile
};

type component_${project.artifactId} = {
    include structure_component
    "skip" : ${project.artifactId}_skip
    # TODO: only ignore implemented so far. To add : disabled and/or masked
    "unconfigured" : string = 'ignore' with match (SELF, '^(ignore)$') # harmless default
    # escaped full unitnames are allowed (or use shortnames and type)
    "unit" ? ${project.artifactId}_unit_type{}
};
