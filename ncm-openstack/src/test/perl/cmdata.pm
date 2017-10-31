# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

=pod

=head1 cmdata module

This module provides raw command data (output and exit code)

=cut

package cmdata;

use strict;
use warnings;
use Readonly;

Readonly my $DEFAULT_OUT => "\n";
Readonly my $DEFAULT_EXIT => 0;

our %cmd;


$cmd{cmd_keystone_db_sync}{command} = "su -s /bin/sh -c /usr/bin/keystone-manage db_sync keystone";
$cmd{cmd_keystone_db_sync}{out} = $DEFAULT_OUT;
$cmd{cmd_keystone_db_sync}{exit} = $DEFAULT_EXIT;


$cmd{cmd_keystone_fernet_setup}{command} = "/usr/bin/keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone";
$cmd{cmd_keystone_fernet_setup}{out} = $DEFAULT_OUT;
$cmd{cmd_keystone_fernet_setup}{exit} = $DEFAULT_EXIT;


$cmd{cmd_keystone_credential_setup}{command} = "/usr/bin/keystone-manage credential_setup --keystone-user keystone --keystone-group keystone";
$cmd{cmd_keystone_credential_setup}{out} = $DEFAULT_OUT;
$cmd{cmd_keystone_credential_setup}{exit} = $DEFAULT_EXIT;

1;
