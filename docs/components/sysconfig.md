### NAME

sysconfig: management of sysconfig files

### DESCRIPTION

The _sysconfig_ component manages system configuration files in 
`/etc/sysconfig.`  These are files which contain key-value pairs. 
However there is the possibility to add verbatim text either
before or after the key-value pair definitions. 

### FILE DEFINITIONS

- `/software/components/sysconfig/files`

    This is an nlist which has the file name (unescaped) as the key, and
    the content information as the value.  The value is an nlist.

- `/software/components/sysconfig/files`/<fname>/

    This is a nlist containing key-value pairs.  Both are strings.  
    There are two special keys "prologue" and "epilogue" which contain
    text which will be copied verbatim into the file before or after 
    the pair definitions, respectively. 

### EXAMPLE

"/software/components/sysconfig/files/scfg" = 
  nlist("epilogue", "export LANG=C",
        "KEY", "VALUE");

This will create the file `/etc/sysconfig/scfg` which contains:

KEY=VALUE
export LANG=C
