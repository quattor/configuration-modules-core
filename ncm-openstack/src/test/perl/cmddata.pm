# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

=pod

=head1 cmddata module

This module provides raw command data (output and exit code) and file content.

=cut
package cmddata;

use strict;
use warnings;

# bunch of commands and their output
our %cmds;
our %files;

$cmds{keystone_db_sync}{command} = "su -s /bin/sh -c /usr/bin/keystone-manage db_sync keystone";

$cmds{keystone_fernet_setup}{command} = "/usr/bin/keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone";

$cmds{keystone_credential_setup}{command} = "/usr/bin/keystone-manage credential_setup --keystone-user keystone --keystone-group keystone";

1;
