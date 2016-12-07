unique template devices;

# keep BlockDevices happy
"/system/network/hostname" = 'x';
"/system/network/domainname" = 'y';

"/hardware/harddisks/sda" = nlist(
    "capacity", 4000, 
);

"/system/blockdevices" = nlist (
    "physical_devs", nlist (
        "sda", nlist ("label", "gpt")
        ),
    "partitions", nlist (
        "sda1", nlist (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda2", nlist (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda3", nlist (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda4", nlist (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda5", nlist (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
        "sda6", nlist (
            "holding_dev", "sda",
            "size", 100,
            "type", "primary", # no defaults !
            ),
    ),
);

"/system/filesystems" = list (
    nlist (
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
