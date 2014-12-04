### NAME

ncm-filecopy: NCM component to manage simple configuration files and services.

### DESCRIPTION

The _filecopy_ component manages services which have
configuration files that can be representated as strings in pan or built by copying
a template already present on the machine (eg. provided by a RPM).  A "restart"
command can be given which will be run whenever the configuration
changes.  

Note: that this does not do any validation checking on the content of
the service configuration.  If this is desired, a service-specific
component should be written.

Note2: "restart" commands are executed after all the files have been updated. There is intentionally no
guarantee on the order of execution if different commands must be executed: this is not necessarily the same
as for checking the files. If two files specify the same restart command, it will be executed only once. If
one of these restrictions is not convenient in your context, a service-specific
component should be written.

### RESOURCES

#### `/software/components/filecopy/forceRestart`: boolean (required)

A boolean that defines if the restart command (if any defined) of the file(s) 
must be executed even though the files were up-to-date (default behaviour is to execute the
restart command only if file content, permissions or owner/group has been changed).

Default: false

#### `/software/components/filecopy/services`: nlist (optional)

This nlist contains one entry by file to manage. The key is the escaped file name. For each file, the
property described below may be specified. Most properties are optional (or have a default value) but either
'config' or 'source' MUST be specified and they are mutually exclusive.

##### config: string (optional but 'config' OR 'source' required)

The file content specified as a string.

Default: none

##### source: string (optional but 'config' OR 'source' required)

The name of a source file already present on the machine to use as the content for the managed file.

Default: none

##### owner: string (optional)

The userid of the file owner. It can also be a 'user:group' specification (like with chown).

Default: none

##### group: string (optional)

The group of the file owner. It is ignored is owner is specified as 'user:group'.

Default: none

##### perms: string (optional)

Permissions of the managed file. If not specified, the default permissions on the system will be used.

Default: none

##### restart: string (optional)

A command to execute if the file is modified. It is typically used to restart a service but any valid
command can be specified, including several commands separated by ';'. If not specified, the file is
updated but no command is executed. As mentionned earlier, restart commands are executed after all files
have been updated and if several files specify the same restart command, it is executed once.

Default: none

##### backup: boolean (required)

This property specifies if an existing version of the file must be backuped before being updated (backup
extension is '.old').

Default: true

##### no\_utf8: boolean (optional)

By default, the file content is converted to UTF8. Define this property to 'true' to prevent this
conversion.

Default: none

##### forceRestart: boolean (required)

A boolean that defines if the restart command (if any defined) 
must be executed even though the file was up-to-date (default behaviour is to execute the
restart command only if file content, permissions or owner/group has been changed).

Note: the global flag 'forceRestart' takes precedence if set to 'true'.

Default: false

### EXAMPLE

##### scenario 1 : Create a file

    prefix '/software/components/filecopy/services/{/tmp/test}';
    'config'='Contents of the file';
    'owner'='root:root';
    'perms'='0644';

##### scenario 2 : Create a script and execute it

    prefix '/software/components/filecopy/services/{/tmp/test.sh}';
    'config' = '#!/bin/bash\n echo Hello World';
    'restart' = '/tmp/test.sh';
    'owner'='root:root';
    'perms'='0755';

##### scenario 3 : Copy a file (/tmp/source)

    prefix '/software/components/filecopy/services/{/tmp/second-file}';
    'source'='/tmp/source';
    'owner'='root:root';
    'perms'='0644';
