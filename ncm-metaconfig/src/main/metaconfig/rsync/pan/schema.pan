declaration template metaconfig/rsync/schema;


type rsync_section = {
    "comment" : string
    "path" : string
    "auth_users" : string[]
    "lock_file" : string
    "secrets_file" : string
    "hosts_allow" : string[]
    "max_connections" : long = 2
    "path" ? string

    "use_chroot" : boolean = true
    "read_only" : boolean = true
    "list" : boolean = false
    "strict_modes" : boolean = true
    "ignore_errors" : boolean = false
    "ignore_nonreadable" : boolean = true
    "transfer_logging" : boolean = false

    "uid" : string = 'rsyncd'
    "gid" : string = 'rsyncd'
    "timeout" : long(0..) = 600

    "refuse_options" : string[] = list('checksum', 'dry-run', 'delete')
    "dont_compress" : string[] = list('*.gz', '*.tgz', '*.zip', '*.z', '*.rpm', '*.deb', '*.iso', '*.bz2', '*.tbz')
};

type rsync_file = {
    "sections" : rsync_section{}
    "log" : string
    "facility" : string
};

