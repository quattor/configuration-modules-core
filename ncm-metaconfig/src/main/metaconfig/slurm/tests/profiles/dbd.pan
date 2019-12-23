object template dbd;

function pkg_repl = { null; };
include 'metaconfig/slurm/dbd';
'/software/components/metaconfig/dependencies' = null;


prefix "/software/components/metaconfig/services/{/etc/slurm/slurmdbd.conf}/contents";

'ArchiveEvents' = true;
'ArchiveJobs' = true;
'ArchiveResvs' = true;
'ArchiveSteps' = false;
'ArchiveSuspend' = false;
'ArchiveTXN' = false;
'ArchiveUsage' = false;
'AuthInfo' = '/var/run/munge/munge.socket.2';
'AuthType' = 'munge';
'DbdHost' = 'master23';
'DebugLevel' = 'debug4';
'PurgeEventAfter' = 30 * 24;
'PurgeJobAfter' = 12 * 30 * 24;
'PurgeResvAfter' = 12 * 30 * 24;
'PurgeStepAfter' = 30 * 24;
'PurgeSuspendAfter' = 30 * 24;
'PurgeTXNAfter' = 12 * 30 * 24;
'PurgeUsageAfter' = 24 * 30 * 24;
'LogFile' = '/var/log/slurmdbd.log';
'PidFile' = '/var/run/slurmdbd.pid';
'SlurmUser' = 'slurm';
'StoragePass' = 'huppelde';
'StorageType' = 'mysql';
'StorageUser' = 'slurmdbd';
