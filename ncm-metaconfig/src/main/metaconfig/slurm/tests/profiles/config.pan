object template config;

function pkg_repl = { null; };
include 'metaconfig/slurm/config';
'/software/components/metaconfig/dependencies' = null;

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/control";

"ControlMachine" = 'master.example.com';
#ControlAddr = ;
#BackupController = ;
#BackupAddr = ;
"AuthAltParameters" = dict("jwt_key", "/etc/slurm/jwt.key");
"AuthAltTypes" = "jwt";
"AuthType" = "munge";
"CryptoType" = "munge";
"ClusterName" = "thecluster";
"CommunicationParameters" = dict("block_null_hash", true);
"DisableRootJobs" = true;
"EnforcePartLimits" = 'NO';
#Epilog=
#EpilogSlurmctld=
"FirstJobId" = 1;
"MaxJobId" = 9999999;
"GresTypes" = list("gpu", "mps");
"GroupUpdateForce" = false;
"GroupUpdateTime" = 600;
"JobContainerType" = "tmpfs";
#JobCredentialPrivateKey=
#JobCredentialPublicCertificate=
#JobFileAppend=0
#JobRequeue=1
"JobSubmitPlugins" = list("lua", "pbs");
#KillOnBadExit=0
#LaunchType=launch/slurm
"LaunchParameters" = dict("use_interactive_step", true);
#Licenses=foo*4,bar
"MailProg" = "/bin/mail";
"MaxJobCount" = 5000;
"MaxStepCount" = 40000;
"MaxTasksPerNode" = 128;
"MinJobAge" = 300;
"MpiDefault" = "none";
#MpiParams=ports=#-#
#"PluginDir" = "/etc/slurm";
#PlugStackConfig=
"PrivateData" = list("jobs", "accounts", "nodes", "reservations", "usage");
"ProctrackType" = "cgroup";
#Prolog=
#PrologFlags=
#PrologSlurmctld=
#PropagatePrioProcess=0;
#PropagateResourceLimits=
#PropagateResourceLimitsExcept=
#RebootProgram=
"ReturnToService" = 1;
#SallocDefaultCommand=
"ScronParameters" = dict("enable", true);

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/process";

"SlurmctldParameters" = dict(
    "power_save_interval", 20,
    "{cloud_reg_addrs}", false,
    "{user_resv_delete}", false,
    "{max_dbd_msg_action}", "discard",
);
"SlurmctldPidFile" = "/var/run/slurmctld.pid";
"SlurmctldPort" = list(6817);
"SlurmdPidFile" = "/var/run/slurmd.pid";
"SlurmdPort" = 6818;
"SlurmdSpoolDir" = "/var/spool/slurm/slurmd";
"SlurmUser" = "slurm";
#SlurmdUser=root
#SrunEpilog=
#SrunProlog=
"StateSaveLocation" = "/var/spool/slurm";
"SwitchType" = "none";
#TaskEpilog=
"TaskPlugin" = list("affinity" , "cgroup");
#TaskProlog=
#TopologyPlugin=topology/tree
#TmpFS=/tmp
#TrackWCKey=no
#TreeWidth=
#UnkillableStepProgram=
#UsePAM=0


prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/timers";

#BatchStartTimeout=10
#CompleteWait=0
#EpilogMsgTime=2000
#GetEnvTimeout=2
#HealthCheckInterval=0
#HealthCheckProgram=
"InactiveLimit" = 0;
"KillWait" = 30;
#MessageTimeout=10
#ResvOverRun=0
#OverTimeLimit=0
"SlurmctldTimeout" = 120;
"SlurmdTimeout" = 300;
#UnkillableStepTimeout=60
#VSizeFactor=0
"WaitTime" = 0;


prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/scheduling";

"DefCpuPerGPU" = 3;
"DefMemPerCPU" = 123;
"FastSchedule" = 1;
"MaxMemPerNode" = 345;
#SchedulerTimeSlice = 30;
"SchedulerType" = "backfill";
"SchedulerParameters" = dict(
    "{batch_sched_delay}", 5,
    "{default_queue_depth}", 128,
    "bf_max_job_test", 1024,
    "bf_continue", true,
    "bf_window", 4320,
    "{no_backup_scheduling}", false,
    "{no_env_cache}", false,
    "{partition_job_depth}", 5,
    );
"DependencyParameters" = dict('{max_depend_depth}', 5);
"SelectType" = "cons_res";
"SelectTypeParameters" = dict("CR_Core_Memory", true);

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/priority";

"PriorityFlags" = list("FAIR_TREE");
"PriorityType" = "multifactor";
"PriorityDecayHalfLife" = 7 * 24 * 60;
"PriorityCalcPeriod" = 5;
"PriorityFavorSmall" = false;
"PriorityMaxAge" = 28 * 24 * 60;
#PriorityUsageResetPeriod=
"PriorityWeightAge" = 5000;
"PriorityWeightFairshare" = 7000;
"PriorityWeightJobSize" = 2500;
#PriorityWeightPartition=
#PriorityWeightQOS=


prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/accounting";

"AccountingStorageEnforce" = list("qos", "safe");
"AccountingStorageHost" = 'slurmdb.example.org';
#AccountingStorageLoc = "/var/spool/slurm/job_accounting.log";"
#AccountingStoragePass=
#AccountingStoragePort=
"AccountingStorageType" = "slurmdbd";
#AccountingStorageUser=
"AccountingStoreFlags" = list("job_comment", "job_env");
#DebugFlags=
#JobCompHost=
"JobCompLoc" = "/var/spool/slurm/job_completions.log";
#JobCompPass=
#JobCompPort=
"JobCompType" = "filetxt";
#JobCompUser=
"JobAcctGatherFrequency" = dict(
    "network", 30,
    "energy", 10,
    );
"JobAcctGatherType" = "cgroup";


prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/logging";

"SlurmctldDebug" = "debug3";
"SlurmctldLogFile" = "/var/log/slurmctld";
"SlurmdDebug" = "debug4";
"SlurmdLogFile" = "/var/log/slurmd";
#SlurmdLogFile=
#SlurmSchedLogFile=
#SlurmSchedLogLevel=


#prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/power";
#SuspendProgram=
#ResumeProgram=
#SuspendTimeout=
#ResumeTimeout=
#ResumeRate=
#SuspendExcNodes=
#SuspendExcParts=
#SuspendRate=
#SuspendTime=


prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/nodes/compute/DEFAULT";
"CPUs" = 4;
"RealMemory" = 3500;
"Sockets" = 4;
"CoresPerSocket" = 1;
"ThreadsPerCore" = 1;
"State" = "UNKNOWN";

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/nodes/compute/compute";
"NodeName" = list("node1", "node2");
"CPUs" = 8;
"RealMemory" = 3500;
"Sockets" = 4;
"CoresPerSocket" = 1;
"ThreadsPerCore" = 2;
"State" = "UNKNOWN";
"Gres/0" = dict(
    "name", "gpu",
    "type", "kepler1",
    "number", 1,
    );
"Gres/1" = dict(
    "name", "gpu",
    "type", "tesla1",
    "number", 1,
    );
"Gres/2" = dict(
    "name", "bandwidth",
    "type", "lustre",
    "consume", false,
    "number", 4 * 1024 * 1024,
    );

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/nodes/down/DEFAULT";
"State" = "FAIL";

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/nodes/down/kaputt";
"DownNodes" = list("node8", "node9");
"State" = "FAILING";
"Reason" = "in progress";

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/nodes/frontend/DEFAULT";
"State" = "UNKNOWN";
"AllowUsers" = list("usera", "userb");

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/nodes/frontend/special";
"FrontendName" = list("login1", "login2");
"State" = "FAILING";
"Reason" = "in progress";

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/partitions/thepartition";
"PartitionName" = "abc";
"Nodes" = list('ALL');
"Default" = true;
"MaxTime" = 3 * 24 * 60;
"State" = "UP";
"DisableRootJobs" = true;

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents/partitions/thepartition-debug";
"Nodes" = list('node2801', 'node2802');
"MaxTime" = 3 * 24 * 60;
"State" = "DOWN";
"DisableRootJobs" = false;
