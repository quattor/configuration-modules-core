declaration template metaconfig/snmp/schema;

# converted from the man pages of snmp.conf, snmpd.conf and snmptrapd.conf
# use the resp types snmp_snmp_conf, snmp_snmpd_conf and snmp_snmptrapd_conf
# the main section are single key/value style

type snmp_snmp_client_behaviour = {
    "defDomain" ? string # application domain
    "defTarget" ? string # application domain target
    "defaultPort" ? long(0..)
    "defVersion" ? string with match(SELF,'^(1|2c|3)$')
    "defCommunity" ? string
    "alias" ? string # NAME DEFINITION
    "dumpPacket" ? boolean # yes
    "doDebugging" ? boolean
    "debugTokens" ? string # TOKEN[,TOKEN...]
    "clientaddr" ? string # [<transport-specifier>:]<transport-address>
    "clientaddrUsesPort" ? boolean # no
    "clientRecvBuf" ? long (0..)
    "clientSendBuf" ? long (0..)
    "noRangeCheck" ? boolean
    "noTokenWarnings" ? boolean
    "reverseEncodeBER" ? boolean
};

type snmp_snmp_snmpv3_settings = {
    "defSecurityName" ? string
    "defSecurityLevel" ? string with match(SELF,'^(noAuthNoPriv|authNoPriv|authPriv)$')
    "defPassphrase" ? string
    "defAuthPassphrase" ? string
    "defPrivPassphrase" ? string
    "defAuthType" ? string with match(SELF,'^(MD5|SHA)$')
    "defPrivType" ? string with match(SELF,'^(DES|AES)$')
    "defContext" ? string
    "defSecurityModel" ? string
    "defAuthMasterKey" ? string # 0xHEXSTRING
    "defPrivMasterKey" ? string # 0xHEXSTRING
    "defAuthLocalizedKey" ? string # 0xHEXSTRING
    "defPrivLocalizedKey" ? string # 0xHEXSTRING
    "sshtosnmpsocketperms" ? string
    "sshtosnmpsocketperms" ? string # MODE [OWNER [GROUP]]
};

type snmp_snmp_server_behaviour = {
    "persistentDir" ? string
    "noPersistentLoad" ? boolean
    "noPersistentSave" ? boolean
    "tempFilePattern" ? string # PATTERN
    "serverRecvBuf" ? long(0..)
    "serverSendBuf" ? long(0..)
};

type snmp_snmp_mib_handling = {
    #"mibdirs" ? string # DIRLIST
    #"mibs" ? string # MIBLIST
    "mibfile" ? string # FILE
    "showMibErrors" ? boolean
    "commentToEOL" ? boolean
    "mibAllowUnderline" ? boolean
    "mibWarningLevel" ? long(0..)
};

type snmp_snmp_output_configuration = {
    "logTimestamp" ? boolean
    "printNumericEnums" ? boolean
    "printNumericOids" ? boolean
    "dontBreakdownOids" ? boolean
    "escapeQuotes" ? boolean
    "quickPrinting" ? boolean
    "printValueOnly" ? boolean
    "dontPrintUnits" ? boolean
    "numericTimeticks" ? boolean
    "printHexText" ? boolean
    "hexOutputLength" ? long
    "suffixPrinting" ? long(0..2)
    "oidOutputFormat" ? long(0..6)
    "extendedIndex" ? boolean
    "noDisplayHint" ? boolean
};

type snmp_snmp_conf_main = {
    include snmp_snmp_client_behaviour
    include snmp_snmp_snmpv3_settings
    include snmp_snmp_server_behaviour
    include snmp_snmp_mib_handling
    include snmp_snmp_output_configuration
};

type snmp_snmp_conf = {
    "main" ? snmp_snmp_conf_main
    "mibdirs" ? string[] # DIRLIST
    "mibdirsprefix" ? string with match(SELF,'^(\+|-)$')
    "mibs" ? string[] # MIBLIST
    "mibsprefix" ? string with match(SELF,'^(\+|-)$')
};

type snmp_snmpd_agent_behaviour = {
    "agentaddress" ? string #[<transport-specifier>:]<transport-address>[,...]
    "agentgroup" ? string # {GROUP|#GID}
    "agentuser" ? string # {USER|#UID}
    "leave_pidfile" ? boolean
    "maxGetbulkRepeats" ? long(0..)
    "maxGetbulkResponses" ? long(0..)
    "engineID" ? string
    "engineIDType" ? long(0..3)
    "engineIDNic" ? string # INTERFACE
};

type snmp_snmpd_snmpv3_authentication = {
    "createUser" ? string # [-e  ENGINEID]  username (MD5|SHA) authpassphrase [DES|AES]
    "defX509ServerPub" ? string # FILE
    "defX509ServerPriv" ? string # FILE
    "defX509ClientCerts" ? string # FILE
};

type snmp_snmpd_access_control = {
    "rouser" ? string # [-s SECMODEL] USER [noauth|auth|priv [OID | -V VIEW [CONTEXT]]]
    "rwuser" ? string # [-s SECMODEL]  USER [noauth|auth|priv [OID | -V VIEW [CONTEXT]]]
    "rocommunity" ? string # COMMUNITY [SOURCE [OID | -V VIEW [CONTEXT]]]
    "rwcommunity" ? string # COMMUNITY [SOURCE [OID | -V VIEW [CONTEXT]]]
    "rocommunity6" ? string # COMMUNITY [SOURCE [OID | -V VIEW [CONTEXT]]]
    "rwcommunity6" ? string # COMMUNITY [SOURCE [OID | -V VIEW [CONTEXT]]]
    "com2sec" ? string # [-Cn CONTEXT] SECNAME SOURCE COMMUNITY
    "com2sec6" ? string # [-Cn CONTEXT] SECNAME SOURCE COMMUNITY
    "com2secunix" ? string # [-Cn CONTEXT] SECNAME SOCKPATH COMMUNITY
    #"group" ? string # GROUP {v1|v2c|usm|tsm|ksm} SECNAME
    "view" ? string # VNAME TYPE OID [MASK]
    "access" ? string # GROUP  CONTEXT  {any|v1|v2c|usm|tsm|ksm} LEVEL PREFX READ WRITE
    "authcommunity" ? string # TYPES  COMMUNITY   [SOURCE [OID | -V VIEW [CONTEXT]]]
    "authuser" ? string # TYPES [-s MODEL] USER  [LEVEL [OID | -V VIEW [CONTEXT]]]
    "authgroup"  ? string # TYPES [-s MODEL] GROUP [LEVEL [OID | -V VIEW [CONTEXT]]]
    "authaccess" ? string # TYPES [-s MODEL] GROUP VIEW [LEVEL [CONTEXT]]
    "setaccess" ? string # GROUP CONTEXT MODEL LEVEL PREFIX VIEW TYPES
};

type snmp_snmpd_system_information = {
    "sysLocation" ? string
    "sysContact" ? string
    "sysName" ? string
    "sysServices" ? long
    "sysDescr" ? string
    "sysObjectID" ? string # OID
    "interface" ? string # NAME TYPE SPEED
    "interface_fadeout" ? string # TIMEOUT
    "interface_replace_old" ? boolean
    "ignoreDisk" ? string
    "skipNFSInHostResources" ? boolean
    "storageUseNFS" ? long(1..2)
    "realStorageUnits" ? string
    "proc" ? string # NAME [MAX [MIN]]
    "procfix" ? string # NAME PROG ARGS
    "disk" ? string # PATH [ MINSPACE | MINPERCENT% ]
    "includeAllDisks" ? string # MINPERCENT%
    "load" ? string # MAX1 [MAX5 [MAX15]]
    "swap" ? string # MIN
    "file" ? string # FILE [MAXSIZE]
    "logmatch" ? string # NAME FILE CYCLETIME REGEX
};

type snmp_snmpd_active_monitoring = {
    "trapcommunity" ? string
    "trapsink" ? string # HOST [COMMUNITY [PORT]]
    "trap2sink" ? string # HOST [COMMUNITY [PORT]]
    "informsink" ? string # HOST [COMMUNITY [PORT]]
    "trapsess" ? string # [SNMPCMD_ARGS] HOST
    "authtrapenable" ?long (1..2)
    "v1trapaddress" ? string # HOST
    "iquerySecName" ? string # NAME
    "agentSecName" ? string # NAME
    "monitor" ? string # [OPTIONS] NAME EXPRESSION
    "notificationEvent" ? string # ENAME NOTIFICATION [-m] [-i OID | -o OID ]*
    "setEvent" ? string # ENAME [-I] OID = VALUE
    "strictDisman" ? boolean
    "linkUpDownNotifications" ? boolean
    "defaultMonitors" ? boolean
    "repeat" ? string # FREQUENCY OID = VALUE
    "cron" ? string # MINUTE HOUR DAY MONTH WEEKDAY  OID = VALUE
    "at" ? string # MINUTE HOUR DAY MONTH WEEKDAY  OID = VALUE
};

type snmp_snmpd_extending_agent = {
    "exec" ? string # [MIBOID] NAME PROG ARGS
    "sh" ? string # [MIBOID] NAME PROG ARGS
    "execfix" ? string # NAME PROG ARGS
    "extend" ? string # [MIBOID] NAME PROG ARGS
    "extendfix" ? string # NAME PROG ARGS
    "pass" ? string # [-p priority] MIBOID PROG
    "pass_persist" ? string # [-p priority] MIBOID PROG
    "disablePerl" ? boolean
    "perlInitFile" ? string # FILE
    "perl" ? string # EXPRESSION
    "dlmod" ? string # NAME PATH
    "proxy" ? string # [-Cn CONTEXTNAME] [SNMPCMD_ARGS] HOST OID [REMOTEOID]
    "smuxpeer" ? string # OID PASS
    "smuxsocket" ? string # <IPv4-address>
    "master" ? string # agentx
    "agentXPerms" ? string # SOCKPERMS [DIRPERMS [USER|UID [GROUP|GID]]]
    "agentXPingInterval" ? long(0..)
    "agentXSocket" ? string # [<transport-specifier>:]<transport-address>[,...]
    "agentXTimeout" ? long(0..)
    "agentXRetries" ? long(0..)
};

type snmp_snmpd_other = {
    "override" ? string # [-rw] OID TYPE VALUE
    "injectHandler" ? string # HANDLER modulename
    "dontLogTCPWrappersConnects" ? boolean
    "table" ? string # NAME
    "add_row" ? string # NAME INDEX(ES) VALUE(S)
};

type snmp_snmpd_conf_main = {
    include snmp_snmpd_agent_behaviour
    include snmp_snmpd_snmpv3_authentication
    include snmp_snmpd_access_control
    include snmp_snmpd_system_information
    include snmp_snmpd_active_monitoring
    include snmp_snmpd_extending_agent
    include snmp_snmpd_other
};

type snmp_snmpd_conf = {
    "main" ? snmp_snmpd_conf_main
    "group" ? string[] # GROUP {v1|v2c|usm|tsm|ksm} SECNAME
};


type snmp_snmptrapd_behaviour = {
    "snmpTrapdAddr" ? string # [<transport-specifier>:]<transport-address>[,...]
    "doNotRetainNotificationLogs" ? boolean
    "doNotLogTraps" ? boolean
    "doNotFork" ? boolean
    "pidFile" ? string # PATH
};

type snmp_snmptrapd_access_control = {
    "authCommunity" ? string # TYPES COMMUNITY  [SOURCE [OID | -v VIEW ]]
    "authUser" ? string # TYPES [-s MODEL] USER  [LEVEL [OID | -v VIEW ]]
    "authGroup" ? string # TYPES [-s MODEL] GROUP  [LEVEL [OID | -v VIEW ]]
    "authAccess" ? string # TYPES [-s MODEL] GROUP VIEW  [LEVEL [CONTEXT]]
    "setAccess" ? string # GROUP CONTEXT MODEL LEVEL PREFIX VIEW TYPES
    "createUser" ? string # username (MD5|SHA) authpassphrase [DES|AES]
    "disableAuthorization" ? boolean
};

type snmp_snmptrapd_logging = {
    "format1" ? string # FORMAT
    "format2" ? string # FORMAT
    "ignoreAuthFailure" ? boolean
    "logOption" ? string
    "outputOption" ? string
};

type snmp_snmptrapd_mysql_logging = {
    "sqlMaxQueue" ? long(0..)
    "sqlSaveInterval" ? long(0..) # seconds
};

type snmp_snmptrapd_notification_processing = {
    #"traphandle" ? string # OID|default PROGRAM [ARGS ...]
    "forward" ? string # OID|default DESTINATION
};

type snmp_snmptrapd_main = {
    include snmp_snmptrapd_behaviour
    include snmp_snmptrapd_access_control
    include snmp_snmptrapd_logging
    include snmp_snmptrapd_mysql_logging
    include snmp_snmptrapd_notification_processing
};

type snmp_snmptrapd_conf = {
    "main" ? snmp_snmptrapd_main
    "traphandle" ? string[] # OID|default PROGRAM [ARGS ...]
};
