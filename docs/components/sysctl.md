### NAME

NCM::sysctl - NCM sysctl configuration component

### SYNOPSIS

Add/modify variables into sysctl configuration file.

### RESOURCES

#### `/software/components/ncm`-sysctl/command : string (required)

Command to use to update sysctl configuration.

Default : `/sbin/sysctl`

#### `/software/components/ncm`-sysctl/compat-v1 : boolean (required)

This property is a boolean making sysctl to accept variable definitions according to v1 of this component. This
is deprecated. If you rely on this, you are advised to convert your configuration to v2 schema.

Default : false

#### `/software/components/ncm`-sysctl/confFile : string (required)

String defining sysctl configuration file. If this value contains a /
character then it will be treated as an absolute path to a file which
is modified in place, and a backup made.

If the value does not contain a / then it will be treated as the name
of a file to be created in `/etc/sysctl.d`. The existing contents of
the file will be overwritten.

Default : `/etc/sysctl.conf`

#### `/software/components/ncm`-sysctl/variables : nlist (optional)

A nlist of key/value defining sysctl variables. There is no check that
the key matches a valid key, so be cautious to use appropriate
variable names. Key names must begin with a letter or an underscore.
Values containing whitespace must include quotes, the component will
not add them.

Default : none.

### EXAMPLES

    "/software/components/sysctl/variables/kernel.shmmni"                  = "4096";
    "/software/components/sysctl/variables/kernel.shmall"                  = "2097152";
    "/software/components/sysctl/variables/net.ipv4.ip_local_port_range" = "1024 65000";
    "/software/components/sysctl/variables/fs.file-max"                 = "65536";
    "/software/components/sysctl/variables/fs.aio-max-size"          = "1048576";
    "/software/components/sysctl/variables/net.core.rmem_default"        = "262144";
    "/software/components/sysctl/variables/net.core.wmem_default"        = "262144";

### DEPENDENCIES

None.

### BUGS

Key names must begin with a letter or underscore, there is no
mechanism to represent keys that do not satisfy this requirement.

Benjamin Chardi <Benjamin.Chardi.M>

### SEE ALSO

sysctl.conf(5), sysctl(8), ncm-ncd(1)
