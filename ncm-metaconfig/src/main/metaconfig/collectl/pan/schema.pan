declaration template metaconfig/collectl/schema;

type collectl_main = {
    "DaemonCommands" : string = "-f /var/log/collectl -r00:00,7 -m -F60 -s+YZ"

    "ReqDir" ? string[] = list("/usr/share/collectl")

    "Libraries" ? string[] # empty by default


    "Grep" ? string = "/bin/grep"
    "Egrep" ? string = "/bin/egrep"
    "Ps" ? string = "/bin/ps"
    "Rpm" ? string = "/bin/rpm"
    "Lspci" ? string = "/sbin/lspci"
    "Lctl" ? string = "/usr/sbin/lctl"

    "PQuery" : string[] = list("/usr/sbin/perfquery")
    "PCounter" ? string[] = list("usr/mellanox/bin/get_pcounter")
    "VStat" ? string[] = list("/usr/mellanox/bin/vstat","/usr/bin/vstat")
    "OfedInfo" : string[] = list("/usr/bin/ofed_info")

    "IbDupCheckFlag" ? boolean = true

    "SubsysCore" ? string[] = list('b','c','d','f','i','j','l','m','n','s','t','x')

    "Interval" ? long(0..) = 10
    "Interval2" ? long(0..) = 60
    "Interval3" ? long(0..) = 120

    "LustreSvcLunMax" ? long(0..) = 10
    "LustreMaxBlkSize" ? long(0..) = 512

    "LustreConfigInt" ? long(0..) = 1
    "InterConnectInt" ? long(0..) = 900

    "LimSVC" ? long(0..) = 30
    "LimIOS" ? long(0..) = 10
    "LimBool" ? long(0..) = 0
    "LimLusKBS" ? long(0..) = 100
    "LimLusReints" ? long(0..) = 1000

    "Port" ? long(0..) = 2655
    "Timeout" ? long = 10

    "MaxZlibErrors" ? long(0..) = 20

    "DefNetSpeed" ? long(0..) = 10000

    "TermHeight" ? long(0..) = 24
    "Resize" : string[] = list("/usr/bin/resize","/usr/X11R6/bin/resize")

    "TimeHiResCheck" ? boolean = true

    "Ipmitool" : string[] = list("/usr/bin/ipmitool")
    "IpmiCache" : string[] = list("/var/run/collectl-ipmicache")
    "IpmiTypes" : string[] = list("fan","temp","current")

    "Passwd" ? string = "/etc/passwd"
    "DiskMaxValue" ? long(0..) = 5000000
    # default DiskFilter list('/cciss/c\d+d\d+ ','hd[ab] ',' sd[a-z]+ ','dm-\d+ ','xvd[a-z] ','fio[a-z]+ ',' vd[a-z]+ ','emcpower[a-z]+ ,'psv\d+ ')
    "DiskFilter" ? string[] # will be joined with |, whitespace is important
    "ProcReadTest" ? boolean = true
};

type collectl_config = {
    "main" : collectl_main
} = nlist();
