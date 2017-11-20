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

$cmds{keystone_db_version_missing}{cmd} = "/usr/bin/keystone-manage db_version";
$cmds{keystone_db_version_missing}{ec} = 1;

$cmds{keystone_db_version}{cmd} = "/usr/bin/keystone-manage db_version";
$cmds{keystone_db_version}{out} = 123;


1;
