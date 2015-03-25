declaration template metaconfig/ganesha/schema;

# the defaults are based on the GPFS FSAL

type ganesha_nfs_protocol = long with SELF == 2 || SELF == 3 || SELF == 4;
type ganesha_transport_protocol = string with SELF == 'TCP' || SELF == 'UDP';
type ganesha_sec_type = string with SELF == 'sys' || SELF == 'krb5' || SELF == 'krb5i' || SELF == 'krb5p';

type ganesha_export_client = {
    "Root_Access" ? string[] # Grant root access to thoses nodes, networks and @netgroups. A hostname can contain wildcards (*?).
    "RW_Access" ? string[] # Provide RW access to thoses nodes, networks and @netgroups. A hostname can contain wildcards (*?).
    "R_Access" ? string[] = list('*') # Provide RW access to thoses nodes, networks and @netgroups. A hostname can contain wildcards (*?).
    "MDONLY_Access" ? string[] = list('*') # Metadata only READ WRITE Access
    "MDONLY_RO_Access" ? string[] = list('*') # Metadata only READ Access

    # alternative method
    "Access" ? string[]
    "Access_Type" ? string # eg rw
    "Squash" ? string # eg root_squash;
} = nlist();

type ganesha_export = {
    include ganesha_export_client
    "clients" ? ganesha_export_client[] # these are parsed first to look for a match

    "Export_Id" : long # Export Id (mandatory)
    "Path" : string # Exported path (mandatory)
    "Pseudo" : string # Pseudo path for NFSv4 export (mandatory)
    "Tag" ? string # Export entry "tag" name. Can be used as an alternative way of addressing the export entry at mount time ( alternate to the 'Path')


    # The anonymous uid/gid (default: -2) for root when its host doesn't have a root_access and for nonroot users when Make_All_Users_Anonymous = TRUE
    "Anonymous_uid" : long = -2
    "Anonymous_gid" : long = -2
    "Make_All_Users_Anonymous" : boolean = false

    "NOSUID" : boolean = true # mask off setuid bit (default: FALSE)
    "NOSGID" : boolean = false # mask off setgid bit (default: FALSE)

    "NFS_Protocols" ? ganesha_nfs_protocol[] # NFS protocols that can be used for accessing this export. (default: 2,3,4)
    "Transport_Protocols" ? ganesha_transport_protocol[] # Transport layer that can be used for accessing this export. (default: UDP,TCP)

    "SecType" ? ganesha_sec_type[] # List of supported RPC_SEC_GSS authentication flavors for this export. (default: "sys")

    "MaxRead" : long(0..) = 32768 # Maximum size for a read operation.
    "MaxWrite" : long(0..) = 32768 # Maximum size for a write operation.
    "PrefRead" : long(0..) = 16384 # Prefered size for a read operation.
    "PrefWrite" : long(0..) = 16384 # Prefered size for a write operation.
    "PrefReaddir" ? long(0..) # Prefered size for a readdir operation.

    "Filesystem_id" ? string # Filesystem ID (default  666.666). This sets the filesystem id for the entries of this export.

    "PrivilegedPort" ? boolean # Should the client to this export entry come from a privileged port ?

    "Cache_Data" ? boolean # Is File content cache enbled for this export entry

    "FS_Specific" ? string # Export entry file system dependant options. eg "cos=1". (NOTHING for GPFS FS)

    "Use_NFS_Commit" : boolean = true # Should we allow for unstable writes that require either a COMMIT request to write to disk or a file opened with O_SYNC

    "Use_Ganesha_Write_Buffer" : boolean = false # Should we use a buffer for unstable writes that resides in userspace memory that Ganesha manages.

    "Use_FSAL_UP" : boolean = true
    "FSAL_UP_Type" : string with SELF == "DUMB"
    "FSAL_UP_Timeout" ? long(0..) = 30
} = nlist();

type ganesha_fsal = {
    "Max_FS_calls" : long(0..) = 0  # maximum number of simultaneous calls to the filesystem. ( 0 = no limit ).
} = nlist();

type ganesha_filesystem = {
    "MaxRead" ? long(0..) = 1048576 # Max read size from FS
    "MaxWrite" ? long(0..) = 1048576 # Max write size to FS

    "Umask" ? string = '0002' # If set, this mask is applied on the mode of created objects.
    "umask" : string = '0' # Override umask setting, an octal number
    "xattr_access_rights" : string = '0400' # defines access mask for extended attributes

    "Link_support" ? boolean = true # hardlink support
    "Symlink_support" ? boolean = true # symlinks support
    "CanSetTime" ? boolean = true  # Is it possible to change file times

    "auth_xdev_export" ? boolean = false # This indicates whether it is allowed to cross a junction in a "LookupPath" (used for export entries).

} = nlist();

type ganesha_GPFS = {
  # no GPFS specific options
} = nlist();

type ganesha_cacheinode_hash = {
    "Index_Size" ? long(0..) = 37 # Size of the array used in the hash (must be a prime number for algorithm efficiency)
    "Alphabet_Length" ? long(0..) = 10 # Number of signs in the alphabet used to write the keys
} = nlist();

type ganesha_cacheinode = {
    # all expiration: -1 = Never
    "Attr_Expiration_Time" ? long = -1 # Time after which attributes should be renewed. A value of 0 will disable this feature
    "Symlink_Expiration_Time" ? long = -1 # Time after which symbolic links should be renewed A value of 0 will disable this feature
    "Directory_Expiration_Time" ? long = -1 # Time after which directory content should be renewed A value of 0 will disable this feature

    "Use_Test_Access" ? long(0..) = 1 # This flag tells if 'access' operation are to be performed explicitely on the FileSystem or only on cached attributes information
    "Use_Getattr_Directory_Invalidation" : long(0..) = 0 # Use getattr as for directory invalidation
    "Use_FSAL_Hash" ? long(0..) = 1 # Do we rely on FSAL to hash handle or not?
} = nlist();

type ganesha_cacheinode_gc_policy = {
    "Entries_HWMark" ? long(0..) = 100000 # High water mark for cache entries
    "Entries_LWMark" ? long(0..) = 50000 # Low water mark for cache_entries
    "Cache_FDs" ? boolean = true # Do we cache fd or not?

    "LRU_Run_Interval" ? long(0..) = 600 # Interval in seconds between runs of the LRU cleaner thread
    "FD_HWMark_Percent" ? long(0..) = 90 # The percentage of the system-imposed maximum of file descriptors above which Ganesha will make greater efforts at reaping.
    "FD_LWMark_Percent" ? long(0..) = 50 # The percentage of the system-imposed maximum of file descriptors below which Ganesha will not reap file descriptonot reap file descriptorsrs.
    "FD_Limit_Percent" ? long(0..) = 99 # The percentage of the system-imposed maximum of file descriptors at which Ganesha will deny requests.

    "Reaper_Work" ? long(0..) = 1000 # Roughly, the amount of work to do on each pass through the thread under normal conditions.  (Ideally, a multipel of the number of lanes.)

    "Biggest_Window" ? long(0..) = 40 # The largest window (as a percentage of the system-imposed limit on FDs) work that we will do in extremis.

    "Required_Progress" ? long(0..) = 5 # Percentage of progress toward the high water mark required in in a pass through the thread when in extremis.

    "Futility_Count" ? long(0..) = 8 # Number of failures to approach the high watermark before we disable caching, when in extremis.
} = nlist();

type ganesha_nfsworker_param = {
    "Nb_Before_GC" : long(0..) = 50 # Number of job before GC on the worker's job pool size
} = nlist();

type ganesha_nfs_core_param = {
    "Nb_Worker" ? long(0..) = 16 # Number of worker threads to be used

    # Port numbers to be used for each RPC protocol
    # Other than NFS defaulting to 2049,
    # the rest default to 0 (let the system use an available ephemeral port)
    # It is useful to override these defaults if Ganesha is operating in a
    # firewalled environment
    "NFS_Port" ? long(0..) = 2049
    "MNT_Port" ? long(0..) = 0
    "NLM_Port" ? long(0..) = 0
    "RQOTA_Port" ? long(0..) = 0

    # The following RPC program numbers should not be changed from default
    # without some specific reason of understanding that clients may be
    # confused by using different RPC program numbers.
    "NFS_Program" ? long(0..) = 100003
    "MNT_Program" ? long(0..) = 100005
    "NLM_Program" ? long(0..) = 100021
    "RQOTA_Program" ? long(0..) = 100011

    "Bind_Addr" ? string # Bind to only a single address With this option set, Ganesha will bind all sockets to the specified address. Default is INADDR_ANY (0.0.0.0), example below

    "Nb_Call_Before_Queue_Avg" ? long(0..) = 1000

    "Dispatch_Max_Reqs" ? long(0..) = 1024 # Global Max Outstanding Requests
    "Dispatch_Max_Reqs_Xprt" ? long(0..) = 50 # Per-Xprt Max Outstanding Requests

    "DRC_Disabled" ? boolean = false # Disable DRC completely
    "DRC_TCP_Npart" ? long(0..) = 1 # Number of hash/rbtree partitions in TCP/per-connection DRCs
    "DRC_TCP_Size" ? long(0..) = 1024 # Upper bound on TCP/per-connection DRC entries
    "DRC_TCP_Cachesz" ? long(0..) = 127 # Size of (per-partition) expected entry caches
    "DRC_TCP_Hiwat" ? long(0..) = 64 # Cache entry retire high water mark (when retire window clear)
    "DRC_TCP_Recycle_Npart" ? long(0..) = 7 # Number of hash/rbtree partitions TCP DRC recycle cache
    "DRC_TCP_Recycle_Expire_S" ? long(0..) = 600 # TTL for unused TCP/per-connection DRCs, in seconds
    "DRC_TCP_Checksum" ? boolean = true # Checksum request headers?
    "DRC_UDP_Npart" ? long(0..) = 17 # Number of hash/rbtree partitions in the shared UDP DRC
    "DRC_UDP_Size" ? long(0..) = 32768 # Upper bound on shared DRC entries
    "DRC_UDP_Cachesz" ? long(0..) = 599 # Size of (per-partition) expected entry caches
    "DRC_UDP_Hiwat" ? long(0..) = 16384 # Cache entry retire high water mark (when retire window clear)
    "DRC_UDP_Checksum" ? boolean = true # Checksum request headers?

    # Specify the types of errors that may be dropped
    "Drop_IO_Errors" ? boolean = true
    "Drop_Inval_Errors" ? boolean = false
    "Drop_Delay_Errors" ? boolean = true

    "Core_Dump_Size" ? long = -1 # Size to be used for the core dump file (if the daemon crashes)

    "Nb_Max_Fd" ? long = 1024 # Maximum Number of open fds

    "Stats_File_Path" : string = "/tmp/ganesha.stats" # The path for the stats file

    "Stats_Update_Delay" : long(0..) = 600 # The delay for producing stats (in seconds)

    "Long_Processing_Threshold" ? long(0..) = 10 # The duration a worker thread is allowed to process a single request without raising a long processing message.

    "TCP_Fridge_Expiration_Delay" ? long = -1 # The delay before idle TCP connection threads will be discarded

    # These options control per client statistics
    "Dump_Stats_Per_Client" ? boolean = false
    "Stats_Per_Client_Directory" ? string = "/tmp"

    "NSM_Use_Caller_Name" ? boolean = false # If the following is TRUE, NSM will use caller name instead of IP address to track failed clients

    "Clustered" ? boolean = false # Is this a clustered environment, Default value is FALSE for Ganesha, but GPFS is clustered

    "MaxRPCSendBufferSize" ? long(0..) = 32768 # The size of each RPC send buffer in bytes and effectively the maximum send size.
    "MaxRPCRecvBufferSize" ? long(0..) = 32768 # The size of each RPC receive buffer in bytes and effectively the maximum receive size.
    "NFS_Protocols" ? ganesha_nfs_protocol[] = list(3,4) # List of NFS Protocol Versions that should be supported
} = nlist();

type ganesha_nfs_dupreq_hash = {
    "Index_Size" : long(0..) = 17 # Size of the array used in the hash (must be a prime number for algorithm efficiency)
    "Alphabet_Length" : long(0..) = 10 # Number of signs in the alphabet used to write the keys
} = nlist();

type ganesha_nfs_ip_name = {
    "Index_Size" : long(0..) = 17 # Size of the array used in the hash (must be a prime number for algorithm efficiency)
    "Alphabet_Length" : long(0..) = 10 # Number of signs in the alphabet used to write the keys
    "Expiration_Time" : long(0..) = 3600 # Expiration time for this cache
} = nlist();

type ganesha_snmp_adm = {
    "snmp_agentx_socket" : string = "tcp:localhost:761"
    "product_id" : long(0..) = 2
    "snmp_adm_log" : string = "/tmp/snmp_adm.log"

    "export_cache_stats" : boolean = true
    "export_requests_stats" : boolean = true
    "export_maps_stats" : boolean = false

    "export_nfs_calls_detail" : boolean = false
    "export_cache_inode_calls_detail" ? boolean = false
    "export_fsal_calls_detail" : boolean = false
} = nlist();

type ganesha_stat_exporter = {
    "Access" : string = "localhost"
    "Port" : long = 10401
} = nlist();

type ganesha_nfsv4 = {
    "Lease_Lifetime" : long(0..) = 90 # Lifetime for NFSv4 Leases Grace period is tied to Lease, but has a maximum value of 60
    "FH_Expire" : boolean = false # Are we using volatile fh ?
    "Returns_ERR_FH_EXPIRED" : boolean = true # Should we return NFS4ERR_FH_EXPIRED if a FH is expired ?
} = nlist();

type ganesha_nfsv4_client_cache = {
    "Index_Size" : long (0..) = 17 # Size of the array used in the hash (must be a prime number for algorithm efficiency)
    "Alphabet_Length" : long(0..) = 10 # Number of signs in the alphabet used to write the keys
} = nlist();


type ganesha_nfs_krb5 = {
    "PrincipalName" ? string = 'nfs' # Principal to be used Default is nfs
    "KeytabPath" ? string = '/etc/krb5.keytab' # Keytab Path Default is /etc/krb5.keytab
    "Active_krb5" ? boolean = true  # TRUE = krb5 support enabled Default is TRUE
} = nlist();

type ganesha_main = {
    "FSAL" : ganesha_fsal
    "NFS_KRB5" : ganesha_nfs_krb5
    "NFSv4_ClientId_Cache" : ganesha_nfsv4_client_cache
    "NFSv4" : ganesha_nfsv4
    "STAT_EXPORTER" : ganesha_stat_exporter
    "SNMP_ADM" : ganesha_snmp_adm
    "FileSystem" : ganesha_filesystem
    "GPFS" : ganesha_GPFS
    "CacheInode_Hash" : ganesha_cacheinode_hash
    "NFS_IP_Name" : ganesha_nfs_ip_name
    "NFS_DupReq_Hash" : ganesha_nfs_dupreq_hash
    "CacheInode" : ganesha_cacheinode
    "CacheInode_GC_Policy" : ganesha_cacheinode_gc_policy
    "NFS_Worker_Param" : ganesha_nfsworker_param
    "NFS_Core_Param" : ganesha_nfs_core_param
} = nlist();

type ganesha_config = {
    "includes" ? string[] # list with filesnames to include
    "exports" : ganesha_export[]
    "main" : ganesha_main
} = nlist();
