declaration template metaconfig/bacula/schema;

type bacula_autochanger = {
    "Name" : string
    "Device" : string[]
    "Changer_Command" : string
    "Changer_Device" : string
};

type bacula_device = {
    "Name" : string
    "Media_Type" : string
    "Device_Type" : string with match(SELF,'^(File|Fifo)$')
    "Random_Access" : boolean
    "Archive_Device" : string
    "Label_Media" : boolean
    "Drive_Index" ? long
    "Autoselect" ? boolean
    "Autochanger" ? boolean
    "AutomaticMount" ? boolean
    "RemovableMedia" ? boolean
    "AlwaysOpen" ? boolean
    "MaximumOpenWait" ? long
    "Maximum_Network_Buffer_Size" ? long
    "Maximum_Block_Size" ? long
};

type bacula_filedaemon = {
    "Name" : string
    "FDport" : long = 9102
    "WorkingDirectory" : string = "/var/spool/bacula"
    "Pid_Directory" : string = "/var/run"
    "Maximum_Concurrent_Jobs" : long = 20
    "Maximum_Network_Buffer_Size" ? long
};

type bacula_message_destinations = {
    "destination" : string
    "address" ? string
    "types" : string[]
};

type bacula_director = {
    "Name" : string
    "Password" : string
    "Monitor" ? boolean
};

type bacula_messages = {
    "Name" : string
    "MailCommand" ? string
    "messagedestinations" : bacula_message_destinations[]
};

type bacula_storage = {
    "Name" : string
    "SDAddress" : string
    "SDPort" : long = 9103
    "WorkingDirectory" : string = "/var/spool/bacula"
    "Pid_Directory" : string = "/var/run"
    "Maximum_Concurrent_Jobs" : long = 20
};

type bacula_main_config = {
    "FileDaemon" ? bacula_filedaemon[]
    "Director" ? bacula_director[]
    "Messages" ? bacula_messages[]
    "Storage" ? bacula_storage[]
    "Device" ? bacula_device[]
    "Autochanger" ? bacula_autochanger[]
};

type bacula_config = {
    "preincludes" ? string[]
    "includes" ? string[]
    "main" ? bacula_main_config
};

