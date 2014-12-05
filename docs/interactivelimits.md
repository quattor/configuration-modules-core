### NAME

NCM::interactivelimits - NCM interactivelimits configuration component

### SYNOPSIS

- Configure()

    Updates the `/etc/security/limits.conf` - file with system limits
    for interactive users.
    This file is read by `/lib/security/pam`\_limits.so and the values
    defined there are respected.
    Returns error in case of failure.

- Unconfigure()

    not available.

### RESOURCES

- `/software/components/interactivelimits/active` : boolean

    Activates/deactivates the component.

- `/software/components/interactivelimits/values` : list

    Defines all values that should be configured in `/etc/security/limits.conf`.

    Example of such a definition from a node profile:

        "/software/components/interactivelimits/values" = list(
          list("username", "soft", "core", "0"),
          list("username", "hard", "nofile", "65536"),
          list("username", "soft", "nproc", "16384"),
          list("username", "hard", "as", "unlimited"),
        );

### DEPENDENCIES

None.

### BUGS

None known.

Vladimir Bahyl <Vladimir.B>

### SEE ALSO

pam(8), ncm-ncd(1)
