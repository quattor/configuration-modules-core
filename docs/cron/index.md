---
layout: documentation
title: cron
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

cron -- NCM component to control cron entries for Linux and Solaris.

### DESCRIPTION

The _cron_ component manages files in the `/etc/cron.d` directory on Linux
and the `/var/spool/cron/crontabs` directory on Solaris.

#### Linux

    Files managed by ncm-cron will have the ncm-cron.cron suffix.  Other files in
    the directory are not affected by this component. The name of each file will be
    taken from the nlist name.

#### Solaris

    Solaris uses an older version of cron that does not make use of a cron.d
    directory for crontabs. Ncm-cron __shares__ the crontab with each user. To make
    this work ncm-cron uses the concept of separate file __sections__ within the
    crontab.  Each __section__ is identified by the use of the tags NCM-CRON BEGIN:
    and NCM-CRON END:. Entries either side of these section identifiers are not
    modified.

    Solaris __does__ have a `/etc/cron.d` directory, however it uses this directory
    for control files such as cron.allow and cron.deny.

### MAIN RESOURCES

#### `/software/components/cron/entries`

A list containing cron structures (described above).

### ENTRY RESOURCES

Each cron entry in the `/software/components/cron/entries` list may
contain the properties and resources described below. One of "frequency"
or "timing" must be specified.

- __command__ : string (required)

    Command line to execute, including all its options.

    Default : None

- __comment__ : string (optional)

    An optional comment to add at the beginning of the cron file.

    Default : None

- __env__ : nlist (optional)

    An optional nlist containing environment variable that must be
    defined before executing the command. Key is
    the variable name, value is variable value.

    Default : None

- __frequency__ : string (optional)

    Execution frequency for the command, using standard cron syntax.
    Minutes field can be 'AUTO' : in this case,
    a random value between 0 and 59 inclusive is generated.
    This can be used to avoid too many machines executing the same
    cron at the same time. See also the "timing" element.

    Default : None

- __group__ : string (optional)

    Group to use to run the command. Defaults to user's primary group.

    Default : user's primary group

- __log__ : nlist (optional)

    A nlist allowing to define specific attributes for cron log file.
    Supported attributes are :

    - name

        name of the log file. If the name is not an absolute file name, file is created in `/var/log.`
        Default name is the cron file name with .log extension in `/var/log.`

    - owner

        owner/group of the log file, using owner:group format. group can be ommitted.

    - mode

        permissions of log file specified as a string interpreted as an octal number.

    - disabled

        A boolean value disabling the redirection of script output/error to a log file

- __name__ : string (required)

    Name of the cron entry file to create.

    Default : None

- __timing__ : nlist (optional)

    If the 'timing' nlist is used to specify the time, it can contain any of the
    keys: 'minute', 'hour', 'day', 'month' and 'weekday'. An unspecified key will
    have a value of '\*'. A further key of 'smear' can be used to specify (in
    seconds) a maximum interval for smearing the start time, which can be as much
    as a day. When a smeared job is created, a random increment between zero and
    the smear time is applied to the start time of the job.  If the start time
    results in the job running on the following day, then all other fields (day,
    weekday, etc) will be suitably modified. When smearing is specified, then the
    start minute (and possibly hour, if smear is more than one hour) must be
    specified as a simple absolute (e.g. '2') and cannot be variations such as
    lists or ranges.  Time specifications such as ranges, lists and steps are
    supported except for named values (e.g.  "1" must be used instead of "mon").

- __user__ : string (optional)

    User to use to run the command.

    Default : root

### EXAMPLE

    "/software/components/cron/entries" = list(
      nlist(
        "name","ls",
        "user","root",
        "group","root",
        "frequency", "*/2 * * * *",
        "command", "/bin/ls"),
      nlist(
        "name","hostname",
        "comment", "some interesting text",
        "frequency", "*/2 * * * *",
        "command", "/bin/hostname"),
        "env", nlist("MAILTO", "admin@example.org"),
      nlist(
        "name", "date",
        "comment", "runs the date sometime within a 3 hour period",
        "timing", nlist(
            "minute", "0",
            "hour", "1",
            "smear", "180"),
        "command", "/bin/date")
      );

On Linux this will create three files in `/etc/cron.d`:
  ls.ncm-cron.cron
  hostname.ncm-cron.cron
  date.ncm-cron.cron

On Solaris three extra entries will be added to the root crontab.

### DEPENDENCIES

None.

### BUGS

#### Linux

    None known.

#### Solaris

    Editing the NCM-CRON BEGIN: and/or the NCM-CRON END: tag within a crontab will
    cause unpredictable behaviour. Possible behavours are duplicate entries or
    entries being removed altogether.

    Editing BETWEEN the tags will cause the edits to be overwritten the next time
    ncm-cron runs.

Charles Loomis <charles.loomis@cern.ch>

S

Guillaume Philippon <>

Mark Wilson <Mark.Wilson@MorganStanley.com>

### VERSION

14.8.0

### SEE ALSO

ncm-ncd(1)
