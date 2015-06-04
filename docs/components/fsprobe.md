### DESCRIPTION

Updates the `/etc/sysconfig/fsprobe` configuration.  This is used by
the CERN-CC-fsprobe package to start fsprobe on the relevant file systems.

The CDB entries are added to the file.  No user editing of the file should
be performed as this will be overwritten on the next execution.

Returns error in case of a failure.

The fields are

    logfile     File to log to : default `/var/log/fsprobe.log`
    mailto      users to mail to when corruption detected
    options     additional arguments for fsprobe
    syslog      log to syslog
    filesystems file systems to monitor (regular expressions)
    dir         directory within the file system to test to
    mailsubject subject of mail
    remotefs    allow probing of remote file systems.  Default is local only.

For example,

    "/software/components/fsprobe/active" = true;
    "/software/components/fsprobe/syslog" = true;
    "/software/components/fsprobe/mailto" = "system.admin@cern.ch";
    "/software/components/fsprobe/options" = "--MultiPattern --RndWait --SleepTime 300 --ContinueOnDiff --DumpBuffers "+fsprobedirectio;

### DEPENDENCIES

CERN-CC-fsprobe

### BUGS

None known.

Tim Bell <>

### SEE ALSO
ncm::hwprobe
