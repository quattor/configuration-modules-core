### DESCRIPTION

This component configures amanda server, the  "Advanced  Maryland  Automatic  
Network  Disk  Archiver"

### FILES

This component generates the following files: 
`/etc/amanda/backupname/amanda.conf`
/etc/amanda/backupname/disklist 

Furthermore, when using virtual tapes (tpchanger='chg-disk') it creates 
(only if these files do not exist previously)
`/etc/amanda/backupname/tapelist`
tapedev\_dir/slotXX
and symbolic to the first slot.

It also label the virtual tapes
(this is very dangerous cause labelling the tapes destroy the content,
have this into account if you already have data in the tapedev directory)

### STRUCTURE

These are the top-level fields provided by the component. For
information on any of these fields' structure, please look amanda's
documentation. 

- `/software/components/amandaserver/backupname/config/general`\_options

    Named list of general configuration options (goes to `/etc/amanda/backupname/amanda.conf`).
    Depending to the value of option 'tpchanger' it might create the virtual tapes in the path 
    specified by option 'tapedev'.

- `/software/components/amandaserver/backupname/config/holdingdisks` : holdingdisk{}

    Named list of `holdingdisk` structures, indexed by `holdingdisk`
    name (goes to `/etc/amanda/backupname/amanda.conf`).

- `/software/components/amandaserver/backupname/config/tapetypes` : tapetype{}

    Named list of `tapetype` structures, indexed by `tapetype` name 
    (goes to `/etc/amanda/backupname/amanda.conf`). 

- `/software/components/amandaserver/backupname/config/dumptypes` : dumptype{}

    Named list of `dumptype` structures, indexed by `dumptype` name 
    (goes to `/etc/amanda/backupname/amanda.conf`).

- `/software/components/amandaserver/backupname/config/interfaces` : interface{}

    Named list of `interface` structures, indexed by `interface` name
    (goes to `/etc/amanda/backupname/amanda.conf`).

- `/software/components/amandaserver/backupname/disklists` : disk\[\]

    List of `disk` structures ((goes to `/etc/amanda/backupname/disklist`)
