object template configure;

# keep BlockDevices happy
"/system/network/hostname" = 'x';
"/system/network/domainname" = 'y';

"/hardware/harddisks/sda" = dict(
    "capacity", 4000,
);

"/system/blockdevices" = dict (
    "physical_devs", dict (
        "sda", dict ("label", "gpt")
        ),
    "partitions", dict (
        "sda1", dict (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda2", dict (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda3", dict (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda4", dict (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda5", dict (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda6", dict (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
    ),
);

"/system/filesystems" = list (
    dict (
        "mount", true,
        "mountpoint", "/boot",
        "preserve", true,
        "format", false,
        "mountopts", "auto",
        "block_device", "partitions/sda1",
        "type", "ext4",
        "freq", 0,
        "pass", 0
        )
);

"/system/filesystems" = {
    # always make a copy

    fs=value("/system/filesystems/0");
    fs["block_device"] = "partitions/sda2";
    fs["mountpoint"] = "/";
    append(fs);

    fs=value("/system/filesystems/0");
    fs["block_device"] = "partitions/sda3";
    fs["mountpoint"] = "/new";
    append(fs);

    fs=value("/system/filesystems/0");
    fs["block_device"] = "partitions/sda4";
    fs["mountpoint"] = "/food";
    fs["label"] = "FRIETJES";
    fs["type"] = "chokotoFS";
    append(fs);

    fs=value("/system/filesystems/0");
    fs["block_device"] = "partitions/sda5";
    fs["mountpoint"] = "/home";
    fs["type"] = "ext4";
    fs["label"] = "HOME";
    append(fs);

    fs=value("/system/filesystems/0");
    fs["block_device"] = "partitions/sda6";
    fs["mountpoint"] = "/special";
    fs["label"] = "BLT";
    fs["type"] = "xfs";
    append(fs);
};

prefix '/software/components/fstab';

'static/fs_types' = list('xfs');
'static/mounts' = list('/', '/boot', '/proc');
'keep/mounts' =  list('/', '/boot', '/home', '/sys');
'keep/fs_types' = list('gpfs', 'ceph', 'swap');
