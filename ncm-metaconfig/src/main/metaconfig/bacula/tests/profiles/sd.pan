object template sd;

include 'metaconfig/bacula/sd';

variable BACULA_DIRECTOR_SHORT = 'director-short-sd';

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-sd.conf}/contents/main/Director/0";
"Name" = format("%s-dir", BACULA_DIRECTOR_SHORT);
"Password" = '@/etc/bacula/pw';
"Monitor" = true;

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-sd.conf}/contents/main/Messages/0";
"Name" = "standard";
"messagedestinations" = list(
    dict(
        "destination", "director",
        "address", format("%s-dir", BACULA_DIRECTOR_SHORT),
        "types", list("all", "!skipped", "!restored"),
    ),
);


prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-sd.conf}/contents/main/Autochanger/0";
"Changer_Command" = '';
"Changer_Device" = '/dev/null';
'Device' = list('dev0-1', 'dev0-2');
'Name' = 'name-0';

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-sd.conf}/contents/main/Autochanger/1";
"Changer_Command" = '';
"Changer_Device" = '/dev/null';
'Device' = list('dev1-1', 'dev1-2');
'Name' = 'name-1';


prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-sd.conf}/contents/main/Device/0";
'AlwaysOpen' = false;
'Archive_Device' = '/dev/null';
'AutomaticMount' = false;
'Device_Type' = 'Fifo';
'Label_Media' = true;
'MaximumOpenWait' = 60;
'Media_Type'= 'NULL';
'Name' = 'dummy';
'Random_Access' = false;
'RemovableMedia' = false;

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-sd.conf}/contents/main/Device/1";
'Archive_Device' = '/some/path';
'Autochanger' = true;
'Autoselect' = true;
'Device_Type' = 'File';
'Drive_Index' = 0;
'Label_Media' = true;
'Maximum_Block_Size' = 524288;
'Maximum_Network_Buffer_Size' = 262144;
'Media_Type' = 'DumpDisk1';
'Name' = 'vDrive-1-0';
'Random_Access' = true;
