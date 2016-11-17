# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/schema;

include 'quattor/types/component';
include 'components/accounts/functions';

# TODO: issue https://github.com/quattor/template-library-core/issues/97: some generic types, candidates for template-library-core
@documentation{
    hwloc (Portable Hardware Locality, hwloc(7)) location, e.g. node:1 for NUMAnode 1
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
} = dict();

type ${project.artifactId}_unit_architecture = string with match(SELF, '^(native|x86(-64)?|ppc(64)?(-le)?|ia64|parisc(64)?|s390x?|sparc(64)?)|mips(-le)?|alpha|arm(64)?(-be)?|sh(64)?|m86k|tilegx|cris$');

type ${project.artifactId}_unit_security = string with match(SELF, '^!?(selinux|apparmor|ima|smack|audit)$');

type ${project.artifactId}_unit_virtualization = string with match(SELF, '^(0|1|vm|container|qemu|kvm|zvm|vmware|microsoft|oracle|xen|bochs|uml|openvz|lxc(-libvirt)?|systemd-nspawn|docker)$');

# TODO: https://github.com/quattor/configuration-modules-core/issues/646: make this more finegrained, e.g. has to be existing unit; or check types
type ${project.artifactId}_valid_unit = string;

# adding new ones
# go to http://www.freedesktop.org/software/systemd/man/systemd.directives.html
# and follow the link to the manual

@documentation{
    Condition/Assert entries in Unit section
    All lists can start with empty string to reset previously defined values.
}
type ${project.artifactId}_unitfile_config_unit_condition = {
    'ACPower' ? boolean
    'Architecture' ? ${project.artifactId}_unit_architecture[]
    'Capability' ? string[]
    'DirectoryNotEmpty' ? string[]
    'FileIsExecutable' ? string[]
    'FileNotEmpty' ? string[]
    'FirstBoot' ? boolean
    'Host' ? string[] # TODO: make custom type for hostname or machineid
    'KernelCommandLine' ? string[]
    'NeedsUpdate' ? string with match(SELF, '^!?/(var|etc)')
    'PathExistsGlob' ? string[]
    'PathExists' ? string[]
    'PathIsDirectory' ? string[]
    'PathIsMountPoint' ? string[]
    'PathIsReadWrite' ? string[]
    'PathIsSymbolicLink' ? string[]
    'Security' ? ${project.artifactId}_unit_security[]
    'Virtualization' ? ${project.artifactId}_unit_virtualization[]
};

@documentation{
the [Unit] section
http://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BUnit%5D%20Section%20Options
}
type ${project.artifactId}_unitfile_config_unit = {
    'After' ? ${project.artifactId}_valid_unit[]
    'AllowIsolate' ? boolean
    'Assert' ? ${project.artifactId}_unitfile_config_unit_condition
    'Before' ? ${project.artifactId}_valid_unit[]
    'BindsTo' ? ${project.artifactId}_valid_unit[]
    'Condition' ? ${project.artifactId}_unitfile_config_unit_condition
    'Conflicts' ? ${project.artifactId}_valid_unit[]
    'DefaultDependencies' ? boolean
    'Description' ? string
    'Documentation' ? string
    'IgnoreOnIsolate' ? boolean
    'IgnoreOnSnapshot' ? boolean
    'JobTimeoutAction' ? string
    'JobTimeoutRebootArgument' ? string
    'JobTimeoutSec' ? long(0..)
    'JoinsNamespaceOf' ? ${project.artifactId}_valid_unit[]
    'NetClass' ? string
    'OnFailure' ? string[]
    'OnFailureJobMode' ? string with match(SELF, '^(fail|replace(-irreversibly)?|isolate|flush|ignore-(dependencies|requirements))$')
    'PartOf' ? ${project.artifactId}_valid_unit[]
    'PropagatesReloadTo' ? string[]
    'RefuseManualStart' ? boolean
    'RefuseManualStop' ? boolean
    'ReloadPropagatedFrom' ? string[]
    'Requires' ? ${project.artifactId}_valid_unit[]
    'RequiresMountsFor' ? string[]
    'RequiresOverridable' ? ${project.artifactId}_valid_unit[]
    'Requisite' ? ${project.artifactId}_valid_unit[]
    'RequisiteOverridable' ? ${project.artifactId}_valid_unit[]
    'SourcePath' ? string
    'StopWhenUnneeded' ? boolean
    'Wants' ? ${project.artifactId}_valid_unit[]
};

@documentation{
the [Install] section
http://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BInstall%5D%20Section%20Options
}
type ${project.artifactId}_unitfile_config_install = {
    'Alias' ? string[]
    'Also' ? ${project.artifactId}_valid_unit[]
    'DefaultInstance' ? string
    'RequiredBy' ? ${project.artifactId}_valid_unit[]
    'WantedBy' ? ${project.artifactId}_valid_unit[]
};

type ${project.artifactId}_unitfile_config_systemd_exec_stdouterr =  string with match(SELF, '^(inherit|null|tty|journal|syslog|kmsg|journal+console|syslog+console|kmsg+console|socket)$');

@documentation{
systemd.kill directives
http://www.freedesktop.org/software/systemd/man/systemd.kill.html
valid for [Service], [Socket], [Mount], or [Swap] sections
}
type ${project.artifactId}_unitfile_config_systemd_kill = {
    'KillMode' ? string with match(SELF, '^(control-group|process|mixed|none)$')
    'KillSignal' ? string with match(SELF, '^SIG(HUP|INT|QUIT|ILL|ABRT|FPE|KILL|SEGV|PIPE|ALRM|TERM|USR[12]|CHLD|CONT|STOP|T(STP|TIN|TOU))$')
    'SendSIGHUP' ? boolean
    'SendSIGKILL' ? boolean
};

@documentation{
systemd.exec directives
http://www.freedesktop.org/software/systemd/man/systemd.exec.html
valid for [Service], [Socket], [Mount], or [Swap] sections
}
type ${project.artifactId}_unitfile_config_systemd_exec = {
    'CPUAffinity' ? long[][] # start with empty list to reset
    'CPUSchedulingPolicy' ? string with match(SELF, '^(other|batch|idle|fifo|rr)$')
    'CPUSchedulingPriority' ? long(1..99) # 99 = highest
    'CPUSchedulingResetOnFork' ? boolean
    'Environment' ? string{}[] # start with empty list
    'EnvironmentFile' ? string[] # overrides variables defined in Environment
    'Group' ? defined_group
    'IOSchedulingClass' ? string with match(SELF, '^([0-3]|none|realtime|best-effort|idle)$')
    'IOSchedulingPriority' ? long(0..7) # 0 = highest
    'LimitAS' ? long(-1..) # The maximum size of the process's virtual memory (address space) in bytes.
    'LimitCORE' ? long(-1..) # Maximum size of a core file
    'LimitCPU' ? long(-1..) # CPU time limit in seconds
    'LimitDATA' ? long(-1..) # he maximum size of the process's data segment (initialized data, uninitialized data, and heap)
    'LimitFSIZE' ? long(-1..) # The maximum size of files that the process may create
    'LimitLOCKS' ? long(-1..) # (Early Linux 2.4 only) A limit on the number of locks
    'LimitMEMLOCK' ? long(-1..) # The maximum number of bytes of memory that may be locked into RAM
    'LimitMSGQUEUE' ? long(-1..) # pecifies the limit on the number of bytes that can be allocated for POSIX message queues for the real user ID of the calling process.
    'LimitNICE' ? long(0..40) # Specifies a ceiling to which the process's nice value can be raised. The actual ceiling for the nice value is calculated as 20 - rlim_cur.
    'LimitNOFILE' ? long(-1..) # Specifies a value one greater than the maximum file descriptor number that can be opened by this process.
    'LimitNPROC' ? long(-1..) # The maximum number of processes (or, more precisely on Linux, threads) that can be created for the real user ID of the calling process.
    'LimitRSS' ? long(-1..) # Specifies the limit (in pages) of the process's resident set (the number of virtual pages resident in RAM).
    'LimitRTPRIO' ? long(-1..) # Specifies a ceiling on the real-time priority that may be set for this process
    'LimitRTTIME' ? long(-1..) # Specifies a limit (in microseconds) on the amount of CPU time that a process scheduled under a real-time scheduling policy may consume without making a blocking system call.
    'LimitSIGPENDING' ? long(-1..) # Specifies the limit on the number of signals that may be queued for the real user ID of the calling process.
    'LimitSTACK' ? long(-1..) # The maximum size of the process stack, in bytes.
    'Nice' ? long(-20..19)
    'OOMScoreAdjust' ? long(-1000..1000)
    'PrivateTmp' ? boolean
    'RootDirectory' ? string
    'StandardError' ? ${project.artifactId}_unitfile_config_systemd_exec_stdouterr
    'StandardInput' ? string with match(SELF, '^(null|tty(-(force|fail))?|socket)$')
    'StandardOutput' ? ${project.artifactId}_unitfile_config_systemd_exec_stdouterr
    'SupplementaryGroups' ? defined_group[]
    'SyslogFacility' ? syslog_facility
    'SyslogIdentifier' ? string
    'SyslogLevel' ? syslog_level
    'SyslogLevelPrefix' ? boolean
    'TTYPath' ? string
    'TTYReset' ? boolean
    'TTYVHangup' ? boolean
    'TTYVTDisallocate' ? boolean
    'UMask' ? string # octal notation, e.g. 0022
    'User' ? defined_user
    'WorkingDirectory' ? string
};

@documentation{
the [Service] section
http://www.freedesktop.org/software/systemd/man/systemd.service.html
}
type ${project.artifactId}_unitfile_config_service = {
    include ${project.artifactId}_unitfile_config_systemd_exec
    include ${project.artifactId}_unitfile_config_systemd_kill
    'BusName' ? string
    'BusPolicy' ? string[] with length(SELF) == 2 && match(SELF[1], '^(see|talk|own)$')
    'ExecReload' ? string
    'ExecStart' ? string
    'ExecStartPost' ? string
    'ExecStartPre' ? string
    'ExecStop' ? string
    'ExecStopPost' ? string
    'GuessMainPID' ? boolean
    'NonBlocking' ? boolean
    'NotifyAccess' ? string with match(SELF, '^(none|main|all)$')
    'PIDFile' ? string with match(SELF, '^/')
    'PermissionsStartOnly' ? boolean
    'RemainAfterExit' ? boolean
    'Restart' ? string with match(SELF, '^(no|on-(success|failure|abnormal|watchdog|abort)|always)$')
    'RestartForceExitStatus' ? long[]
    'RestartPreventExitStatus' ? long[]
    'RestartSec' ? long(0..) # TODO default is 100ms, which can't be expressed like this
    'RootDirectoryStartOnly' ? boolean
    'Sockets' ? ${project.artifactId}_valid_unit[]
    'SuccessExitStatus' ? long[]
    'TimeoutSec' ? long(0..)
    'TimeoutStartSec' ? long(0..)
    'TimeoutStopSec' ? long(0..)
    'Type' ? string with match(SELF, '^(simple|forking|oneshot|dbus|notify|idle)$')
    'WatchdogSec' ? long(0..)
} with {
    if(exists(SELF['Type']) && (SELF['Type'] == 'dbus') && (! exists(SELF['BusName']))) {
        error('BusName has to be specified with Type=dbus');
    };
    true;
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
