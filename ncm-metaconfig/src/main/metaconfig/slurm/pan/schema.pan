declaration template metaconfig/slurm/schema;


@{ Schema for slurm configuration, see
https://slurm.schedmd.com
}

include 'pan/types';

type slurm_debuglevel = choice('quiet', 'fatal', 'error', 'info', 'verbose',
    'debug', 'debug2', 'debug3', 'debug4', 'debug5');

type slurm_gres = {
    'name' : string
    'type' ? string
    'consume' : boolean = true
    'number' : long(0..)
};


@{all intervals in seconds}
type slurm_job_gather_frequency = {
    'energy' ? long(0..)
    'filesystem' ? long(0..)
    'network' ? long(0..)
    'task' ? long(0..)
};

type slurm_msg_aggregation = {
    'WindowMsgs' ? long(0..)
    'WindowTime' ? long(0..)
};

type slurm_power_parameters = {
    @{in seconds}
    'balance_interval' ? long(0..)
    'capmc_path' ? absolute_file_path
    'cap_watts' ? long(0..)
    @{percentage of the difference between a node's minimum and maximum power consumption}
    'decrease_rate' ? long(0..)
    @{in milliseconds}
    'get_timeout' ? long(0..)
    @{percentage of the difference between a node's minimum and maximum power consumption}
    'increase_rate' ? long(0..)
    'job_level' ? boolean
    'job_no_level' ? boolean
    'lower_threshold' ? long(0..)
    @{in seconds}
    'recent_job' ? long(0..)
    @{in milliseconds}
    'set_timeout' ? long(0..)
    'set_watts' ? long(0..)
    @{percentage of its current cap}
    'upper_threshold' ? long(0..)
};

type slurm_sbcast_parameters = {
    'DestDir' ? absolute_file_path
    'Compression' ? choice("lz4", "zlib", "none")

};

type slurm_dependency_parameters = {
    'disable_remote_singleton' ? boolean
    '{kill_invalid_depend}' ? boolean
    '{max_depend_depth}' ? long(0..)
};

type slurm_scheduler_parameters = {
    'assoc_limit_stop' ? boolean
    @{in seconds}
    '{batch_sched_delay}' ? long(0..)
    'bb_array_stage_cnt' ? long(0..)
    'bf_busy_nodes' ? boolean  # should be set without argument
    'bf_continue' ? boolean  # should be set without argument
    @{in seconds}
    'bf_interval' ? long(0..)
    'bf_job_part_count_reserve' ? long(0..)
    'bf_max_job_array_resv' ? long(0..)
    'bf_max_job_assoc' ? long(0..)
    'bf_max_job_part' ? long(0..)
    'bf_max_job_start' ? long(0..)
    'bf_max_job_test' ? long(0..)
    'bf_max_job_user' ? long(0..)
    'bf_max_job_user_part' ? long(0..)
    'bf_max_time' ? long(0..256)
    'bf_min_age_reserve' ? long(0..)
    'bf_min_prio_reserve' ? long(0..)
    'bf_resolution' ? long(0..)
    'bf_window' ? long(0..)
    'bf_window_linear' ? long(0..)
    'bf_yield_interval' ? long(0..)
    'bf_yield_sleep' ? long(0..)
    'build_queue_timeout' ? long(0..)
    '{default_queue_depth}' ? long(0..)
    'defer' ? boolean
    'delay_boot' ? long(0..)
    'default_gbytes' ? boolean
    'disable_hetero_steps' ? boolean
    'enable_hetero_steps' ? boolean
    'enable_user_top' ? boolean
    'Ignore_NUMA' ? boolean
    'inventory_interval' ? long(0..)
    '{kill_invalid_depend}' ? boolean with {
        deprecated(0, 'kill_invalid_depend has moved to DependencyParameters'); true;
    }
    'max_array_tasks' ? long(0..)   # should be smaller than MaxArraySize
    '{max_depend_depth}' ? long(0..) with {deprecated(0, 'max_depend_depth has moved to DependencyParameters'); true; }
    'max_rpc_cnt' ? long(0..)
    'max_sched_time' ? long(0..)
    'max_script_size' ? long(0..)
    'max_switch_wait' ? long(0..)
    '{no_backup_scheduling}' ? boolean
    '{no_env_cache}' ? boolean
    'pack_serial_at_end' ? boolean
    '{partition_job_depth}' ? long(0..)
    'preempt_reorder_count' ? long(0..)
    'preempt_strict_order' ? boolean
    'preempt_youngest_first' ? boolean
    'nohold_on_prolog_fail' ? boolean
    'reduce_completing_frag' ? boolean
    'requeue_setup_env_fail' ? boolean
    'salloc_wait_nodes' ? boolean
    'sbatch_wait_nodes' ? boolean
    'sched_interval' ? long(0..)
    'sched_max_job_start' ? long(0..)
    'sched_min_interval' ? long(0..)
    'spec_cores_first' ? boolean
    'step_retry_count' ? long(0..)
    'step_retry_time' ? long(0..)
    'whole_pack' ? boolean
};

type slurm_select_type_parameters = {
    'OTHER_CONS_RES' ? boolean
    'NHC_ABSOLUTELY_NO' ? boolean
    'NHC_NO_STEPS' ? boolean
    'NHC_NO' ? boolean
    'CR_CPU' ? boolean
    'CR_CPU_Memory' ? boolean
    'CR_Core' ? boolean
    'CR_Core_Memory' ? boolean
    'CR_ONE_TASK_PER_CORE' ? boolean
    'CR_CORE_DEFAULT_DIST_BLOCK' ? boolean
    'CR_LLN' ? boolean
    'CR_Pack_Nodes' ? boolean
    'CR_Socket' ? boolean
    'CR_Socket_Memory' ? boolean
    'CR_Memory' ? boolean
};

type slurm_task_plugin_param = {
    'Boards' ? boolean
    'Cores' ? boolean
    'Cpusets' ? boolean
    'None' ? boolean
    'Sched' ? boolean
    'Sockets' ? boolean
    'Threads' ? boolean
    'SlurmdOffSpec' ? boolean
    'Verbose' ? boolean
    'Autobind' ? boolean
};

type slurm_topology_param = {
    'Dragonfly' ? boolean
    'NoCtldInAddrAny' ? boolean
    'NoInAddrAny' ? boolean
    'TopoOptional' ? boolean
};

type slurm_conf_health_check = {
    'HealthCheckInterval' ? long(0..)
    'HealthCheckNodeState' ? choice('ALLOC', 'ANY', 'CYCLE', 'IDLE', 'MIXED')[]
    'HealthCheckProgram' ? absolute_file_path
};


type slurm_control_resourcelimits = choice( 'ALL', 'NONE', 'AS', 'CORE', 'CPU', 'DATA', 'FSIZE',
    'MEMLOCK', 'NOFILE', 'NPROC', 'RSS', 'STACK');

type slurm_mpi_params = {
    @{port or port range}
    'ports' ? long(0..)[] with {length(SELF) == 1 || length(SELF) == 2}
};

type slurm_launch_params = {
    'batch_step_set_cpu_freq' ? boolean
    'cray_net_exclusive' ? boolean
    'disable_send_gids' ? boolean
    'enable_nss_slurm' ? boolean
    'lustre_no_flush' ? boolean
    'mem_sort' ? boolean
    'mpir_use_nodeaddr' ? boolean
    'send_gids' ? boolean
    'slurmstepd_memlock' ? boolean
    'slurmstepd_memlock_all' ? boolean
    'test_exec' ? boolean
    'use_interactive_step' ? boolean
};

type slurm_authalt_params = {
    'disable_token_creation' ? boolean
    'jwt_key' ? absolute_file_path
};

type slurm_conf_control = {
    'AllowSpecResourcesUsage' ? long(0..1)  # actually a boolean, defaults to 0 for non-Cray systems
    'AuthAltParameters' ? slurm_authalt_params
    'AuthAltTypes' ? choice('jwt')
    'AuthInfo' ? string[]
    'AuthType' ? choice('none', 'munge')
    'BackupController' ? string
    'BackupAddr' ? type_ipv4
    'BurstBufferType' ? choice('none', 'datawarp')
    'CheckpointType' ? choice('blcr', 'none', 'ompi')
    'ChosLoc' ? absolute_file_path  # see https://github.com/scanon/chos
    'CliFilterPlugins' ? string[]
    'ClusterName' : string
    'CompleteWait' ? long(0..65535)
    'ControlMachine' : string
    'ControlAddr' ? type_ipv4

    'CoreSpecPlugin' ? choice('cray', 'none')
    'CpuFreqDef' ? choice( 'Conservative', 'OnDemand', 'Performance', 'PowerSave')
    'CpuFreqGovernors' ? choice('Conservative', 'OnDemand', 'Performance', 'PowerSave', 'UserSpace')
    'CryptoType' ? choice("munge", "openssl")
    'DebugFlags' ? choice( 'Backfill', 'BackfillMap', 'BGBlockAlgo', 'BGBlockAlgoDeep', 'BGBlockPick',
        'BGBlockWires', 'BurstBuffer', 'CPU_Bind', 'CpuFrequency', 'DB_ASSOC', 'DB_EVENT', 'DB_JOB', 'DB_QOS',
        'DB_QUERY', 'DB_RESERVATION', 'DB_RESOURCE', 'DB_STEP', 'DB_USAGE', 'DB_WCKEY', 'Elasticsearch', 'Energy',
        'ExtSensors', 'Federation', 'FrontEnd', 'Gres', 'HeteroJobs', 'Gang', 'JobContainer', 'License',
        'NodeFeatures', 'NO_CONF_HASH', 'Power', 'Priority', 'Profile', 'Protocol', 'Reservation', 'SelectType',
        'Steps', 'Switch', 'TimeCray', 'TraceJobs', 'Triggers')[]

    'DefaultStorageHost' ? string
    'DefaultStorageLoc' ? string
    'DefaultStoragePass' ? string
    'DefaultStoragePort' ? long(0..)
    'DefaultStorageType' ? choice("filetxt", "mysql", "none")
    'DefaultStorageUser' ? string

    'DisableRootJobs' ? boolean    # YES/NO
    'EnforcePartLimits' ? choice("ALL", "ANY", "NO", "YES")
    'ExtSensorsFreq' ? long(0..)
    'ExtSensorsType' ? choice('none', 'rrd')
    'FairShareDampeningFactor' ? long(1..)
    'FastSchedule' ? long(0..2)
    'FederationParameters' ? dict
    'FirstJobId' ? long(0..)
    'GresTypes' ? string[]
    'GroupUpdateForce' ? boolean # 0/1
    'GroupUpdateTime' ? long(0..)
    'JobCheckpointDir' ? absolute_file_path
    'JobContainerType' ? choice('cncu', 'tmpfs', 'none')
    'JobCredentialPrivateKey' ? absolute_file_path
    'JobCredentialPublicCertificate' ? absolute_file_path
    'JobFileAppend' ? boolean # 0/1
    'JobRequeue' ? boolean # 0/1
    'JobSubmitPlugins' ? choice('lua', 'pbs', 'all_partitions', 'require_timelimit', 'throttle')[]
    'KillOnBadExit' ? boolean # 0/1
    'LaunchType' ? choice( 'aprun', 'poe', 'runjob', 'slurm')
    'LaunchParameters' ? slurm_launch_params
    'Licenses' ? string[]
    'MailProg' ? absolute_file_path
    @{0 disables array jobs, the value of MaxJobCount should be much larger than MaxArraySize}
    'MaxArraySize' ? long(0..4000001)
    'MaxJobCount' ? long(0..200000)
    'MaxJobId' ? long(0..67108863)
    'MaxMemPerCPU' ? long(0..)
    'MaxMemPerNode' ? long(0..)
    'MaxStepCount' ? long(0..)
    'MaxTasksPerNode' ? long(0..65533)
    'MpiDefault' ? choice("openmpi", "pmi2", "pmix", "none")
    'MpiParams' ? slurm_mpi_params
    'PluginDir' ? absolute_file_path[]  # colon-separated
    'PlugStackConfig' ? absolute_file_path  # defaults to plugstack.conf in the slurm conf dir
    'PreemptMode' ? choice('OFF', 'CANCEL', 'CHECKPOINT', 'GANG', 'REQUEUE', 'SUSPEND')
    'PreemptType' ? choice( 'none', 'partition_prio', 'qos')
    'ProctrackType' ? choice( 'cgroup', 'cray', 'linuxproc', 'lua', 'sgi_job', 'pgid')
    'PropagatePrioProcess' ? long(0..2)
    'PropagateResourceLimits' ? slurm_control_resourcelimits
    'PropagateResourceLimitsExcept' ? slurm_control_resourcelimits
    'RebootProgram' ? absolute_file_path
    'ReconfigFlags' ? choice( 'KeepPartInfo', 'KeepPartState')
    @{Separate multiple exit code, does not support ranges}
    'RequeueExit' ? long[]
    @{Separate multiple exit code, does not support ranges}
    'RequeueExitHold' ? long[]
    'ReturnToService' : long(0..2)

    'NodeFeaturesPlugins' ? choice('knl_cray', 'knl_generic')
    'MailDomain' ? string
    'MemLimitEnforce' ? boolean # yes/no
    'MinJobAge' ? long(0..)
    'MsgAggregationParams' ? slurm_msg_aggregation
    'PrivateData' ? choice('accounts', 'cloud', 'events', 'jobs', 'nodes', 'partitions',
        'reservations', 'usage', 'users')[]
    'RoutePlugin' ? choice("default", "topology")   # prefix=route/
    'SallocDefaultCommand' ? string
    'SbcastParameters' ? slurm_sbcast_parameters
    'SrunPortRange' ? string   # ideally the range contains at least 1000 ports
    'TmpFS' ? absolute_file_path
    'TrackWCKey' ? boolean
    'TreeWidth' ? long(0..65533)
    'UnkillableStepProgram' ? absolute_file_path
    'UsePAM' ? boolean
    'VSizeFactor' ? long(0..65533)
};

type slurm_conf_prolog_epilog = {
    'Epilog' ? absolute_file_path
    'EpilogSlurmctld' ? absolute_file_path
    'Prolog' ? absolute_file_path
    'PrologEpilogTimeout' ? long(0..) # seconds
    'PrologFlags' ? choice( 'Alloc', 'Contain', 'NoHold', 'Serial', 'X11')[]
    'PrologSlurmctld' ? absolute_file_path
    'ResvEpilog' ? absolute_file_path
    @{in minutes}
    'ResvOverRun' ? long(0..65533) # TODO: support UNLIMITED via -1 value
    'ResvProlog' ? absolute_file_path
    'SrunEpilog' ? absolute_file_path
    'SrunProlog' ? absolute_file_path
    'TaskEpilog' ? absolute_file_path
    'TaskProlog' ? absolute_file_path
};

type slurm_ctld_parameters = {
    'allow_user_triggers' ? boolean
    'cloud_dns' ? boolean
    '{cloud_reg_addrs}' ? boolean
    'enable_configless' ? boolean
    'idle_on_node_suspend' ? boolean
    'power_save_interval' ? long(0..)
    'power_save_min_interval' ? long(0..)
    '{max_dbd_msg_action}' ? choice('discard', 'exit')
    'preempt_send_user_signal' ? boolean
    'reboot_from_controller' ? boolean
    '{user_resv_delete}' ? boolean
};

type slurm_conf_process = {
    'MCSParameters' ? dict # see https://slurm.schedmd.com/mcs.html
    'MCSPlugin' ? choice( 'none', 'account', 'group', 'user')

    'PowerParameters' ? slurm_power_parameters
    'PowerPlugin' ? choice("cray", "none")

    'SlurmUser' ? string
    'SlurmdUser' ? string
    'SlurmctldParameters' ? slurm_ctld_parameters
    'SlurmctldPidFile' ? absolute_file_path
    'SlurmctldPlugstack' ? string[]
    @{a port range}
    'SlurmctldPort' ? long(0..)[] with {length(SELF) == 1 || length(SELF) == 2}
    'SlurmdPidFile' ? absolute_file_path
    'SlurmdPort' ? long(0..)
    'SlurmdSpoolDir' ? absolute_file_path

    'StateSaveLocation' ? absolute_file_path
    'SwitchType' ? choice("cray", "none", "ncrt")   # prefix = "switch/"
    'TaskPlugin' ? choice('affinity', 'cgroup', 'none')[]
    'TaskPluginParam' ? slurm_task_plugin_param
    'TopologyParam' ? slurm_topology_param
    'TopologyPlugin' ? choice('3d_torus', 'node_rank', 'none', 'tree')
};

type slurm_conf_timers = {
    'BatchStartTimeout' ? long(0..)
    'CompleteWait' ? long(0..)
    'EioTimeout' ? long(0..65533)
    'EpilogMsgTime' ? long(0..)
    'GetEnvTimeout' ? long(0..)
    'InactiveLimit' ? long(0..)
    'KeepAliveTime' ? long(0..65533)
    'KillWait' ? long(0..65533)
    'MessageTimeout' ? long(0..)
    'OverTimeLimit' ? long(0..)  # minutes
    'ReturnToService' ? long(0..2)
    'SlurmctldTimeout' ? long(0..65533)
    'SlurmdTimeout' ? long(0..65533)
    'TCPTimeout' ? long(0..)
    'UnkillableStepTimeout' ? long(0..)
    'WaitTime' ? long(0..65533)
};

type slurm_conf_scheduling = {
    'DefMemPerCPU' ? long(0..)
    'DefMemPerNode' ? long(0..)
    'DefCpuPerGPU' ? long(0..)
    'FastSchedule' ? long
    'MaxMemPerNode' ? long(0..)
    'SchedulerTimeSlice' ? long(5..65533)
    'SchedulerParameters' ? slurm_scheduler_parameters
    'DependencyParameters' ? slurm_dependency_parameters
    'SchedulerType' ? choice('backfill', 'builtin', 'hold')  # prefix="sched/"
    'SelectType' ? choice('bluegene', 'cons_res', 'cray', 'linear', 'serial', 'cons_tres')  # prefix="select/"
    'SelectTypeParameters' ? slurm_select_type_parameters
};


type slurm_conf_job_priority = {
    @{in minutes}
    'PriorityDecayHalfLife' ? long(0..)
    @{in minutes}
    'PriorityCalcPeriod' ? long(0..)
    'PriorityFavorSmall' ? boolean
    'PriorityFlags' ? choice( 'ACCRUE_ALWAYS', 'CALCULATE_RUNNING', 'DEPTH_OBLIVIOUS', 'FAIR_TREE',
        'INCR_ONLY', 'MAX_TRES', 'SMALL_RELATIVE_TO_TIME' )[]
    'PriorityParameters' ? dict
    @{in minutes}
    'PriorityMaxAge' ? long(0..)
    'PriorityUsageResetPeriod' ? choice( 'NONE', 'NOW', 'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')
    'PriorityType' ? choice("basic", "multifactor")
    'PriorityWeightAge' ? long(0..)
    'PriorityWeightFairshare' ? long(0..)
    'PriorityWeightJobSize' ? long(0..)
    'PriorityWeightPartition' ? long(0..)
    'PriorityWeightQOS' ? long(0..)
    'PriorityWeightTRES' ? string[]   # key-value pairs
};

type slurm_job_gather_params = {
    'NoShared' ? boolean
    'UsePss' ? boolean
    'NoOverMemoryKill' ? boolean
};

type slurm_conf_accounting = {
    'AccountingStorageBackupHost' ? string
    'AccountingStorageEnforce' ? choice('associations', 'limits', 'nojobs', 'nosteps',
        'qos', 'safe', 'wckeys', 'all')[]
    'AccountingStorageHost' ? string
    'AccountingStorageLoc' ? string
    'AccountingStoragePass' ? string
    'AccountingStoragePort' ? long(0..)
    'AccountingStorageTRES' ? string[]
    'AccountingStorageType' ? choice("filetxt", "none", "slurmdbd")
    'AccountingStorageUser' ? string
    'AccountingStoreJobComment' ? boolean

    'AcctGatherNodeFreq' ? long(0..) # for acct_gather_energy/rapl plugin set a value less than 300
    'AcctGatherEnergyType' ? choice('none', 'ipmi', 'rapl')
    'AcctGatherInfinibandType' ? choice('none', 'ofed')
    'AcctGatherFilesystemType' ? choice('none', 'lustre')
    'AcctGatherProfileType' ? choice('none', 'hdf5')

    'JobCompHost' ? string
    'JobCompLoc' ? string
    'JobCompPass' ? string
    'JobCompPort' ? long(0..)
    'JobCompType' ? choice("none", "elasticsearch", "filetxt", "mysql", "script")
    'JobCompUser' ? string

    'JobAcctGatherType' ? choice("linux", "none", "cgroup")
    'JobAcctGatherFrequency' ? slurm_job_gather_frequency
    'JobAcctGatherParams' ? slurm_job_gather_params
};

type slurm_conf_logging = {
    'LogTimeFormat' ? choice("iso8601", "iso8601_ms", "rfc5424", "rfc5424_ms", "clock", "short", "thread_id")
    'SlurmctldDebug' ? slurm_debuglevel
    'SlurmctldLogFile' ? absolute_file_path
    'SlurmctldSyslogDebug' ? slurm_debuglevel
    'SlurmdDebug' ? slurm_debuglevel
    'SlurmdLogFile' ? absolute_file_path
    'SlurmdSyslogDebug' ? slurm_debuglevel
    'SlurmSchedLogFile' ? absolute_file_path
    'SlurmSchedLogLevel' ? long(0..1)
};

type slurm_conf_power = {
    'ResumeProgram' ? absolute_file_path
    'ResumeRate' ? long(0..)
    'ResumeTimeout' ? long(0..)
    'SuspendProgram' ? absolute_file_path
    'SuspendTimeout' ? long(0..)
    'SuspendExcNodes' ? string[]
    'SuspendExcParts' ? string[]
    @{number of nodes per minute}
    'SuspendRate' ? long(0..)
    @{in seconds}
    'SuspendTime' ? long(0..)
};

type slurm_conf_compute_nodes = {
    'NodeName' ? string[]
    'NodeHostname' ? string[]
    'NodeAddr' ? string[]
    'Boards' ? long(0..)
    'CoreSpecCount' ? long(0..)
    'CoresPerSocket' ? long(0..)
    'CPUs' ? long(0..)
    'CpuSpecList' ? long(0..)[]
    'Feature' ? string[]
    'Gres' ? slurm_gres[]
    @{in megabytes}
    'MemSpecLimit' ? long(0..)
    'Port' ? long(0..)
    'Procs' ? long(0..)
    @{in megabytes}
    'RealMemory' ? long(0..)
    'Reason' ? string   # quotes is multiple words
    'Sockets' ? long(0..)
    'SocketsPerBoard' ? long(0..)
    'State' ? choice('CLOUD', 'DOWN', 'DRAIN', 'FAIL', 'FAILING', 'FUTURE', 'UNKNOWN')
    'ThreadsPerCore' ? long(0..)
    @{in megabytes}
    'TmpDisk' ?  long(0..)
    'TRESWeights' ? dict()
    'Weight' ? long(0..)
};

type slurm_conf_down_nodes = {
    'DownNodes' ? string[]
    'Reason' ? string  # quota formultiple words
    'State' ? choice('DOWN', 'DRAIN', 'FAIL', 'FAILING', 'UNKNOWN')
};

type slurm_conf_frontend_nodes = {
    'AllowGroups' ? string[]
    'AllowUsers' ? string[]
    'DenyGroups' ? string[]
    'DenyUsers' ? string[]
    'FrontendName' ? string[]
    'FrontendAddr' ? string[]
    'Port' ? long(0..)
    'Reason' ? string
    'State' ? choice('DOWN', 'DRAIN', 'FAIL', 'FAILING', 'UNKNOWN')
};

type slurm_partition_select_type = {
    'CR_Core' ? boolean
    'CR_Core_Memory' ? boolean
    'CR_Socket' ? boolean
    'CR_Socket_Memory' ? boolean
};

type slurm_conf_partition = {
    'AllocNodes' ? string[]
    'AllowAccounts' ? string[]
    'AllowGroups' ? string[]
    'AllowQos' ? string[]
    'Alternate' ? string
    'Default' ? boolean
    @{in megabytes}
    'DefMemPerCPU' ? long(0..)
    @{in megabytes}
    'DefMemPerNode' ? long(0..)
    'DenyAccounts' ? string[]
    'DenyQos' ? string[]
    'DefaultTime' ? string
    'DisableRootJobs' ? boolean
    'ExclusiveUser' ? boolean
    @{in seconds}
    'GraceTime' ? long(0..)
    'Hidden' ? boolean
    'LLN' ? boolean
    'MaxCPUsPerNode' ? long(0..)
    @{in megabytes}
    'MaxMemPerCPU' ? long(0..)
    @{in megabytes}
    'MaxMemPerNode' ? long(0..)
    'MaxNodes' ? long(0..)
    @{in minutes}
    'MaxTime' ? long(0..)
    'MinNodes' ? long(0..)
    'Nodes' ? string[]
    'OverSubscribe' ? choice('EXCLUSIVE', 'FORCE', 'YES', 'NO')
    'PartitionName' ? string
    'PreemptMode' ? choice('OFF', 'CANCEL', 'CHECKPOINT', 'GANG', 'REQUEUE', 'SUSPEND')
    'PriorityJobFactor' ? long(0..65533)
    'PriorityTier' ? long(0..65533)
    'QOS' ? string
    'ReqResv' ? boolean
    'RootOnly' ? boolean
    'SelectTypeParameters' ? slurm_partition_select_type
    'State' ? choice('UP', 'DOWN', 'DRAIN', 'INACTIVE')
    'TRESBillingWeights' ? dict
};

type slurm_conf_nodes = {
    @{key is used as nodename, unless NodeName attribute is set}
    'compute' : slurm_conf_compute_nodes{}
    @{key is used as nodename, unless DownNodes attribute is set}
    'down'? slurm_conf_down_nodes{}
    @{key is used as nodename, unless FrontendName attribute is set}
    'frontend' ? slurm_conf_frontend_nodes{}
};

type slurm_conf = {
    'control' : slurm_conf_control
    'process' : slurm_conf_process
    'health' ? slurm_conf_health_check
    'timers' ? slurm_conf_timers
    'prepilogue' ? slurm_conf_prolog_epilog
    'scheduling' : slurm_conf_scheduling
    'priority' : slurm_conf_job_priority
    'accounting' : slurm_conf_accounting
    'logging' : slurm_conf_logging
    'power' ? slurm_conf_power
    'nodes' ? slurm_conf_nodes
    @{key is used as PartitionName, unless PartitionName attribute is set}
    'partitions' ? slurm_conf_partition{}
};

type slurm_cgroups_conf = {
    'AllowedDevicesFile' ? absolute_file_path
    'AllowedKmemSpace' ? long(0..)
    'AllowedRAMSpace' ? long(0..)
    'AllowedSwapSpace' ? long(0..)
    'CgroupAutomount' ? boolean
    'CgroupMountpoint' ? absolute_file_path
    'ConstrainCores' ? boolean
    'ConstrainDevices' ? boolean
    'ConstrainKmemSpace' ? boolean
    'ConstrainRAMSpace' ? boolean
    'ConstrainSwapSpace' ? boolean
    'MaxRAMPercent' ? double(0..)
    'MaxSwapPercent' ? double(0..)
    'MaxKmemPercent' ? double(0..)
    'MemorySwappiness' ? long(0..100)
    'MinKmemSpace' ? long(0..)
    'MinRAMSpace' ? long(0..)
    'TaskAffinity' ? boolean
};

type slurm_spank_plugin = {
    @{plugin is optional (if not optional, it is required)}
    'optional' ? boolean
    'plugin' : absolute_file_path
    'arguments' ? dict()
};

type slurm_spank_includes = {
    'directory' : absolute_file_path
};

type slurm_spank_conf = {
    'plugins' ? slurm_spank_plugin[]
    'includes' ? slurm_spank_includes[]
};

type slurm_topology_leaf_switch = {
    'switch': string
    'nodes': type_fqdn[]
};

type slurm_topology_spine_switch = {
    'switch': string
    'switches': string[]
};

type slurm_topology_conf = {
    'leafswitch' : slurm_topology_leaf_switch[]
    'spineswitch' : slurm_topology_spine_switch[]
};

type slurm_acct_gather_conf = {
    @{in seconds}
    'EnergyIPMIFrequency' ? long(0..)
    'EnergyIPMICalcAdjustment' ? boolean
    'EnergyIPMIPowerSensors' ? boolean
    'EnergyIPMIUsername' ? string
    'EnergyIPMIPassword' ? string
    'ProfileHDF5Dir' ? absolute_file_path
    'ProfileHDF5Default' ? choice('All', 'None', 'Energy', 'Filesystem', 'Network', 'Task')
    'InfinibandOFEDPort' ? long(0..)
};

type slurm_dbd_conf = {
    'ArchiveDir' ? absolute_file_path
    'ArchiveEvents' ? boolean
    'ArchiveJobs' ? boolean
    'ArchiveResvs' ? boolean
    'ArchiveScript' ? absolute_file_path
    'ArchiveSteps' ? boolean
    'ArchiveSuspend' ? boolean
    'ArchiveTXN' ? boolean
    'ArchiveUsage' ? boolean
    'AuthAltParameters' ? slurm_authalt_params
    'AuthAltTypes' ? choice('jwt')
    'AuthInfo' ? string
    'AuthType' ? choice('none', 'munge')
    'CommitDelay' ? long(1..)
    'DbdBackupHost' ? string
    'DbdAddr' ? string
    'DbdHost' ? string
    # TODO: must be equal to the AccountingStoragePort parameter in the slurm.conf
    'DbdPort' ? long(0..)
    'DebugFlags' ? choice('DB_ARCHIVE', 'DB_ASSOC', 'DB_EVENT', 'DB_JOB', 'DB_QOS', 'DB_QUERY', 'DB_RESERVATION',
        'DB_RESOURCE', 'DB_STEP', 'DB_USAGE', 'DB_WCKEY', 'FEDERATION')[]
    'DebugLevel' ? slurm_debuglevel
    'DebugLevelSyslog' ? slurm_debuglevel
    'DefaultQOS' ? string
    'LogFile' ? absolute_file_path
    'LogTimeFormat' ? choice("iso8601", "iso8601_ms", "rfc5424", "rfc5424_ms", "clock", "short")
    'MaxQueryTimeRange' ? long(0..)  # unsure of this type
    'MessageTimeout' ? long(0..)
    'PidFile' ? absolute_file_path
    'PluginDir' ? absolute_file_path
    'PrivateData' ? choice( 'accounts', 'events', 'jobs', 'reservations', 'usage', 'users')[]
    @{in hours}
    'PurgeEventAfter' ? long(1..)
    @{in hours}
    'PurgeJobAfter' ? long(1..)
    @{in hours}
    'PurgeResvAfter' ? long(1..)
    @{in hours}
    'PurgeStepAfter' ? long(1..)
    @{in hours}
    'PurgeSuspendAfter' ? long(1..)
    @{in hours}
    'PurgeTXNAfter' ? long(1..)
    @{in hours}
    'PurgeUsageAfter' ? long(1..)
    'SlurmUser' ? string
    'StorageHost' ? string
    'StorageBackupHost' ? string
    'StorageLoc' ? absolute_file_path
    'StoragePass' ? string
    'StoragePort' ? long(0..)
    'StorageType' ? choice("mysql")
    'StorageUser' ? string
    'TCPTimeout' ? long(0..)
    'TrackWCKey' ? boolean
    'TrackSlurmctldDown' ? boolean
};

type slurm_job_container_per_node_conf = {
    'AutoBasePath' ? boolean
    'Basepath' ? absolute_file_path
    'InitScript' ? absolute_file_path
};

type slurm_job_container_node_conf = {
    include slurm_job_container_per_node_conf
    'NodeName' : string[]
};

type slurm_job_container_conf = {
    'Default' ? slurm_job_container_per_node_conf
    'Nodes' ? slurm_job_container_node_conf[]
};

type slurm_gres_autodetect_conf = {
    'AutoDetect' ? choice('nvml', 'rsmi', 'off')
};

type slurm_gres_per_node_conf = {
    include slurm_gres_autodetect_conf
    'NodeName' : string[]
    'Cores' ? long[]
    'Count' ? long(0..)
    'File' ? absolute_file_path
    'Flags' ? choice('CountOnly')[]
    'Links' ? long(0..)[]
    'Name' ? choice('gpu', 'mps', 'nic', 'mic')
    'Type' ? string
};

type slurm_gres_conf = {
    'Default' ? slurm_gres_autodetect_conf
    'Nodes' ? slurm_gres_per_node_conf[]
};
