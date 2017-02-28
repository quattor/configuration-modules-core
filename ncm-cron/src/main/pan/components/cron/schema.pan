${componentschema}

include 'quattor/types/component';

@documentation{
    Function to check that other log properties are not present when disabled is true
}
function structure_cron_log_valid = {
    if (is_defined(SELF['disabled']) && SELF['disabled']) {
        if (is_defined(SELF['name']) ||
            is_defined(SELF['owner']) ||
            is_defined(SELF['mode']) ) {
                error('cron log file properties are present despite log file creation has been disabled.');
        };
    };
    true;
};

type structure_cron_syslog = {
    'facility' : string = 'user'
    'level' : string = 'notice'
    'tagprefix' : string = 'ncm-cron.' with (!match(SELF, '\s')) # prefix tag
    'tag' ? string with (!match(SELF, '\s')) # use this fixed tag instead of name
};

@documentation{
    Define specific attributes for cron log file.
}
type structure_cron_log = {
    @{A boolean disabling the redirection of script output/error to a log file}
    'disabled' ? boolean
    @{Name of the log file. If the name is not an absolute file name, file is created in /var/log.
    Default name is the cron filename with .log extension in /var/log.}
    'name' ? string
    @{Owner/group of the log file, using owner[:group] format. Group can be ommitted.}
    'owner' ? string
    @{Permissions of log file specified as a string interpreted as an octal number.}
    'mode' ? string
} with structure_cron_log_valid(SELF);

type structure_cron_timing = {
    'minute' ? string
    'hour' ? string
    'day' ? string
    'month' ? string
    'weekday' ? string
    'smear' ? long(0..1440)
};

type structure_cron = {
    @{Filename (without suffix) of the cron entry file to create.}
    'name' : string
    @{User to use to run the command. Defaults to root if none defined}
    'user' ? string
    @{Group to use to run the command. Defaults to user's primary group.}
    'group' ? string
    @{Execution frequency for the command, using standard cron syntax.
      Minutes field can be 'AUTO :' in which case,
      a random value between 0 and 59 inclusive is generated.
      This can be used to avoid too many machines executing the same
      cron at the same time. See also the C<timing> element.}
    'frequency' ? string
    @{If the 'timing' dict is used to specify the time, it can contain any of the
      keys: 'minute', 'hour', 'day', 'month' and 'weekday'. An unspecified key will
      have a value of '*'. A further key of 'smear' can be used to specify (in
      minutes) a maximum interval for smearing the start time, which can be as much
      as a day. When a smeared job is created, a random increment between zero and
      the smear time is applied to the start time of the job.  If the start time
      results in the job running on the following day, then all other fields (day,
      weekday, etc) will be suitably modified. When smearing is specified, then the
      start minute (and possibly hour, if smear is more than one hour) must be
      specified as a simple absolute (e.g. '2') and cannot be variations such as
      lists or ranges.  Time specifications such as ranges, lists and steps are
      supported except for named values (e.g. "1" must be used instead of "mon").}
    'timing' ? structure_cron_timing
    @{Command line to execute, including all its options.}
    'command' : string
    @{An optional comment to add at the beginning of the cron file.}
    'comment' ? string
    @{An optional dict containing environment variable that must be
      defined before executing the command. Key is
      the variable name, value is variable value.}
    'env' ? string{}
    'log' ? structure_cron_log
    'syslog' ? structure_cron_syslog
} with {
    if (exists(SELF['log']) && exists(SELF['syslog'])) {
        error("At most one of log or syslog can be defined");
    };
    if (!exists(SELF['timing']) && !exists(SELF['frequency'])) {
        error("One of timing or frequency must be defined");
    };

    true;
};

type cron_component = {
    include structure_component
    @{A list containing cron structures (described above).}
    'entries' ? structure_cron[]
    'deny' ? string[]
    'allow' ? string[]
    # required for multi os
    'securitypath' : string = '/etc' # Linux default
};
