declaration template metaconfig/telegraf/schema;

include 'pan/types';

type telegraf_time_interval_string = string with match(SELF, '\d+([num]?s|m|h|d)');

type telegraf_file_size_string = string with match(SELF, '\d+[KM]B');

type telegraf_global_tags = string_trimmed{};

type telegraf_agent = {
    @{ Default data collection interval for all inputs }
    'interval' ? telegraf_time_interval_string

    @{
        Rounds collection interval to 'interval'
        ie, if interval="10s" then always collect on :00, :10, :20, etc.
    }
    'round_interval' ? boolean

    @{
        Telegraf will send metrics to outputs in batches of at most
        metric_batch_size metrics.
        This controls the size of writes that Telegraf sends to output plugins.
    }
    'metric_batch_size' ? long(1..)

    @{
        Maximum number of unwritten metrics per output.  Increasing this value
        allows for longer periods of output downtime without dropping metrics at the
        cost of higher maximum memory usage.
    }
    'metric_buffer_limit' ? long(1..)

    @{
        Collection jitter is used to jitter the collection by a random amount.
        Each plugin will sleep for a random time within jitter before collecting.
        This can be used to avoid many plugins querying things like sysfs at the
        same time, which can have a measurable effect on the system.
    }
    'collection_jitter' ? telegraf_time_interval_string

    @{
        Default flushing interval for all outputs. Maximum flush_interval will be
        flush_interval + flush_jitter
    }
    'flush_interval' ? telegraf_time_interval_string

    @{
        Jitter the flush interval by a random amount. This is primarily to avoid
        large write spikes for users running a large number of telegraf instances.
        ie, a jitter of 5s and interval 10s means flushes will happen every 10-15s
    }
    'flush_jitter' ? telegraf_time_interval_string

    @{
        By default or when set to "0s", precision will be set to the same
        timestamp order as the collection interval, with the maximum being 1s.
            ie, when interval = "10s", precision will be "1s"
                when interval = "250ms", precision will be "1ms"
        Precision will NOT be used for service inputs. It is up to each individual
        service input to set the timestamp at the appropriate precision.
        Valid time units are "ns", "us" (or "µs"), "ms", "s".
    }
    'precision' ? telegraf_time_interval_string

    @{ Log at debug level. }
    'debug' ? boolean

    @{ Log only error level messages. }
    'quiet' ? boolean

    @{
        Log target controls the destination for logs and can be one of "file",
        "stderr" or, on Windows, "eventlog".  When set to "file", the output file
        is determined by the "logfile" setting.
    }
    'logtarget' ? choice('file', 'stderr')

    @{
        Name of the file to be logged to when using the "file" logtarget.
        If set to the empty string then logs are written to stderr.
    }
    'logfile' ? absolute_file_path

    @{
        The logfile will be rotated after the time interval specified.
        When set to 0 no time based rotation is performed.
        Logs are rotated only when written to, if there is no log activity rotation may be delayed.
    }
    'logfile_rotation_interval' ? telegraf_time_interval_string

    @{
        The logfile will be rotated when it becomes larger than the specified size.
        When set to 0 no size based rotation is performed.
    }
    'logfile_rotation_max_size' ? telegraf_file_size_string

    @{
        Maximum number of rotated archives to keep, any older logs are deleted.
        If set to -1, no archives are removed.
    }
    'logfile_rotation_max_archives' ? long(-1..)

    @{
        Pick a timezone to use when logging or type 'local' for local time.
        Example: America/Chicago
    }
    'log_with_timezone' ? string_trimmed

    @{
        Override default hostname, if empty use os.Hostname()
    }
    'hostname' ? type_hostname

    @{
        If set to true, do no set the "host" tag in the telegraf agent.
    }
    'omit_hostname' ? boolean
};

# Common to all plugin types
type telegraf_plugin_common = {
    @{ Name an instance of a plugin. }
    'alias' ? string_trimmed


    ## Metric Filtering

    @{
        An array of glob pattern strings.
        Only metrics whose measurement name matches a pattern in this list are emitted.
    }
    'namepass' ? string_trimmed[]

    @{
        The inverse of namepass. If a match is found the metric is discarded.
        This is tested on metrics after they have passed the namepass test.
    }
    'namedrop' ? string_trimmed[]

    @{
        An array of glob pattern strings.
        Only fields whose field key matches a pattern in this list are emitted.
    }
    'fieldpass' ? string_trimmed[]

    @{
        The inverse of fieldpass. Fields with a field key matching one of the patterns will be discarded from the metric.
        This is tested on metrics after they have passed the fieldpass test.
    }
    'fielddrop' ? string_trimmed[]

    @{
        An array of glob pattern strings. Only tags with a tag key matching one of the patterns are emitted.
        In contrast to tagpass, which will pass an entire metric based on its tag,
        taginclude removes all non matching tags from the metric.
        Any tag can be filtered including global tags and the agent host tag.
    }
    'taginclude' ? string_trimmed[]

    @{
        The inverse of taginclude. Tags with a tag key matching one of the patterns will be discarded from the metric.
        Any tag can be filtered including global tags and the agent host tag.
    }
    'tagexclude' ? string_trimmed[]

    @{
        A table mapping tag keys to arrays of glob pattern strings.
        Only metrics that contain a tag key in the table and a tag value matching one of its patterns is emitted.
    }
    'tagpass' ? string_trimmed[]{}

    @{
        The inverse of tagpass. If a match is found the metric is discarded.
        This is tested on metrics after they have passed the tagpass test.
    }
    'tagdrop' ? string_trimmed[]{}
};

# Common to Input, Aggregator and Output plugins
type telegraf_iao_plugin_common = {
    @{ Override the base name of the measurement. (Default is the name of the input). }
    'name_override' ? string_trimmed

    @{ Specifies a prefix to attach to the measurement name. }
    'name_prefix' ? string_trimmed

    @{ Specifies a suffix to attach to the measurement name. }
    'name_suffix' ? string_trimmed
};

type telegraf_plugin_input = extensible {
    include telegraf_plugin_common
    include telegraf_iao_plugin_common

    @{
        Overrides the interval setting of the agent for the plugin.
        How often to gather this metric. Normal plugins use a single global interval,
        but if one particular input should be run less or more often, you can configure that here.
    }
    'interval' ? telegraf_time_interval_string

    @{
        Overrides the precision setting of the agent for the plugin.
        Collected metrics are rounded to the precision specified as an interval.
        When this value is set on a service input, multiple events occuring at the same timestamp
        may be merged by the output database.
    }
    'precision' ? telegraf_time_interval_string

    @{
        Overrides the collection_jitter setting of the agent for the plugin.
        Collection jitter is used to jitter the collection by a random interval.
    }
    'collection_jitter' ? telegraf_time_interval_string

    @{
        A map of tags to apply to a specific input's measurements.
    }
    'tags' ? string_trimmed{}
};

type telegraf_plugin_output = extensible {
    include telegraf_plugin_common
    include telegraf_iao_plugin_common

    @{
        The maximum time between flushes.
        Use this setting to override the agent flush_interval on a per plugin basis.
    }
    'flush_interval' ? telegraf_time_interval_string

    @{
        The amount of time to jitter the flush interval.
        Use this setting to override the agent flush_jitter on a per plugin basis.
    }
    'flush_jitter' ? telegraf_time_interval_string

    @{
        The maximum number of metrics to send at once.
        Use this setting to override the agent metric_batch_size on a per plugin basis.
    }
    'metric_batch_size' ? long(1..)

    @{
        The maximum number of unsent metrics to buffer.
        Use this setting to override the agent metric_buffer_limit on a per plugin basis.
    }
    'metric_buffer_limit' ? long(1..)
};


type telegraf_plugin_processor = extensible {
    include telegraf_plugin_common

    @{
        The order in which the processor(s) are executed.
        If this is not specified then processor execution order will be random.
    }
    'order' ? long(1..)
};

type telegraf_plugin_aggregator = extensible {
    include telegraf_plugin_common
    include telegraf_iao_plugin_common

    @{
        The period on which to flush & clear each aggregator.
        All metrics that are sent with timestamps outside of this period will be ignored by the aggregator.
    }
    'period' ? telegraf_time_interval_string

    @{
        The delay before each aggregator is flushed.
        This is to control how long for aggregators to wait before receiving metrics from input plugins,
        in the case that aggregators are flushing and inputs are gathering on the same interval.
    }
    'delay' ? telegraf_time_interval_string

    @{
        The duration when the metrics will still be aggregated by the plugin,
        even though they're outside of the aggregation period.
        This is needed in a situation when the agent is expected to receive
        late metrics and it's acceptable to roll them up into next aggregation period.
    }
    'grace' ? telegraf_time_interval_string

    @{
        If true, the original metric will be dropped by the aggregator and will not get sent to the output plugins.
    }
    'drop_original' ? boolean

    @{
        A map of tags to apply to the measurement - behavior varies based on aggregator.
    }
    'tags' ? string_trimmed{}
};


type service_telegraf = {
    'global_tags' ? telegraf_global_tags
    'agent' ? telegraf_agent
    'inputs' ? telegraf_plugin_input[]{}
    'processors' ? telegraf_plugin_processor[]{}
    'aggregators' ? telegraf_plugin_aggregator[]{}
    'outputs' ? telegraf_plugin_output[]{}
};
