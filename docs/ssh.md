### NAME

NCM::ssh - NCM SSH configuration component

### DESCRIPTION

Update the SSH client and/or daemon configuration files, preserving their
permissions. Replace changed option values and add new options to the end of the
configuration file(s).

If any changes were made in the daemon configuration file, tell the SSH daemon to
reload the new configuration by executing the following command:

    `/sbin/service` sshd reload

### RESOURCES

#### `/software/components/ssh/client` : nlist (optional)

This nlist contains 2 option sets describing respectively options that must be defined 
an their values and options that must be commented out.

##### `/software/components/ssh/client/options` : nlist (optional)

Options that must be set and their value. See schema for allowed options.

##### `/software/components/ssh/client/comment`\_options : nlist (optional)

Options that must be commented out. This is the same set of options as those which can be
set. If an option is in both list, definition takes precedence.

See schema for allowed options.

#### `/software/components/ssh/daemon` : nlist (optional)

This nlist contains 2 option sets describing respectively options that must be defined 
an their values and options that must be commented out.

##### `/software/components/ssh/daemon/options` : nlist (optional)

Options that must be set and their value. See schema for allowed options.

##### `/software/components/ssh/daemon/comment`\_options : nlist (optional)

Options that must be commented out. This is the same set of options as those which can be
set. If an option is in both list, definition takes precedence.

See schema for allowed options.

### DEPENDENCIES

None.

### FILES

- `/etc/ssh/sshd_config`

    The SSH daemon configuration file.

- `/etc/ssh/ssh_config`

    The SSH client configuration file.

### BUGS

None known.

Teemu Sidoroff <Teemu.S>

### SEE ALSO

ncm-ncd(1), sshd(8), sshd\_config(5), ssh\_config(5)
