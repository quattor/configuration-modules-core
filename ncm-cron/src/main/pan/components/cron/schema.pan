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

@documentation{
    Validate contents of cron timing fields (see CRONTAB(5) for details)

    Cron timing fields can contain complex expressions (e.g. "1,5,13-23/2"). Rather than validate these in
    depth the aim here is to catch things that are obviously wrong, such as:
        * characters which are not valid in cron fields
        * out of range numbers (e.g. "35" in the hour field)
        * names in the wrong field (e.g. "tue" in the day of month field)
}
function valid_cron_timing = {
    if (ARGC != 4) {
        error(format('%s: expected 4 parameters, received %d', FUNCTION, ARGC));
    };

    timing_value = to_lowercase(ARGV[0]);
    lower_bound = ARGV[1];
    upper_bound = ARGV[2];
    text_regex = ARGV[3];

    # Check that the field contains only valid characters
    if (!match(timing_value, '^(?:[a-z0-9/*\-,]+)$')) error(format('"%s" contains invalid characters', timing_value));

    # Find runs of digits and validate them against provided bounds
    foreach(k; v; matches(timing_value, '([0-9]+)')) {
        i = to_long(v);
        if (i < lower_bound) error(format('Value %d is below lower bound of %d', i, lower_bound));
        if (i > upper_bound) error(format('Value %d is above upper bound of %d', i, upper_bound));
    };

    # Find runs of letters and validate them against provided regex
    foreach(k; v; matches(timing_value, '([a-z]+)')) {
        if (!match(v, text_regex)) error(format('"%s" is not a valid value for this field item', v));
    };

    # Ignore all other characters
    true;
};

@documentation{ Convenience wrapper for validating cron minute field }
function valid_cron_minute = valid_cron_timing(ARGV[0], 0, 59, '^(?![a-z]).+$');

@documentation{ Convenience wrapper for validating cron hour field }
function valid_cron_hour = valid_cron_timing(ARGV[0], 0, 23, '^(?![a-z]).+$');

@documentation{ Convenience wrapper for validating cron day of month field }
function valid_cron_day_of_month = valid_cron_timing(ARGV[0], 1, 31, '^(?![a-z]).+$');

@documentation{ Convenience wrapper for validating cron month field }
function valid_cron_month = valid_cron_timing(ARGV[0], 1, 12, '^(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)$');

@documentation{ Convenience wrapper for validating cron day of week field }
function valid_cron_day_of_week = valid_cron_timing(ARGV[0], 0, 7, '^(?:mon|tue|wed|thu|fri|sat|sun)$');

type structure_cron_timing = {
    @{ minute of hour (0-59) }
    'minute' ? string with valid_cron_minute(SELF)
    @{ hour of day (0-23) }
    'hour' ? string with valid_cron_hour(SELF)
    @{ day of month (1-31) }
    'day' ? string with valid_cron_day_of_month(SELF)
    @{ month of year (1-12 or three-letter abbreviated lowercase name) }
    'month' ? string with valid_cron_month(SELF)
    @{ day of week (0-7 or three-letter abbreviated lowercase name) }
    'weekday' ? string with valid_cron_day_of_week(SELF)
    @{ Interval (in minutes) over which to randomly smear the start time of the job }
    'smear' ? long(0..1440)
};

@documentation{
    Validate contents of cron frequency field
}
function valid_cron_frequency = {
    if (ARGC != 1) {
        error(format('%s: expected 1 parameter, received %d', FUNCTION, ARGC));
    };

    frequency = ARGV[0];

    if (match(frequency, '^@(?:reboot|yearly|annually|monthly|weekly|daily|midnight|hourly)$')) {
        return(true);
    };

    fields = split(' ', frequency);

    if (length(fields) != 5) {
        error(format('cron frequency "%s" should have 5 fields, it only has %d', frequency, length(fields)));
    };

    match(fields[0], '^AUTO$') || valid_cron_minute(fields[0]);
    valid_cron_hour(fields[1]);
    valid_cron_day_of_month(fields[2]);
    valid_cron_month(fields[3]);
    valid_cron_day_of_week(fields[4]);

    true;
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
    'frequency' ? string with valid_cron_frequency(SELF)
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
        error("Only one of log or syslog may be defined, not both.");
    };
    if (exists(SELF['timing']) && exists(SELF['frequency'])) {
        error("Only one of timing or frequency may be defined, not both.");
    };
    if (!exists(SELF['timing']) && !exists(SELF['frequency'])) {
        error("Either timing or frequency must be defined.");
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
