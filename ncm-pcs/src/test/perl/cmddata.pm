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

$cmds{cluster_ok}{cmd} = "pcs cluster status";

$cmds{cluster_notok}{cmd} = "pcs cluster status";
$cmds{cluster_notok}{ec} = 1;

$cmds{status_nodes}{cmd} = 'pcs status nodes both';
$cmds{status_nodes}{out} = <<EOF;
Corosync Nodes:
 Online: nodea nodeb
 Offline:
Pacemaker Nodes:
 Online: nodea nodeb
 Standby:
 Maintenance:
 Offline:
Pacemaker Remote Nodes:
 Online:
 Standby:
 Maintenance:
 Offline:
EOF

$cmds{status_nodes_maint}{cmd} = 'pcs status nodes both';
$cmds{status_nodes_maint}{out} = <<EOF;
Corosync Nodes:
 Online: nodea nodeb
 Offline:
Pacemaker Nodes:
 Online: nodea
 Standby:
 Maintenance: nodeb
 Offline:
Pacemaker Remote Nodes:
 Online:
 Standby:
 Maintenance:
 Offline:
EOF

$cmds{status_nodes_remote}{cmd} = 'pcs status nodes both';
$cmds{status_nodes_remote}{out} = <<EOF;
Corosync Nodes:
 Online: nodea nodeb
 Offline:
Pacemaker Nodes:
 Online: nodea nodeb
 Standby:
 Maintenance:
 Offline:
Pacemaker Remote Nodes:
 Online: nodec
 Standby:
 Maintenance:
 Offline:
EOF

$files{empty_config}{path} = "/var/lib/pcsd/quattor.config";
$files{empty_config}{txt} = "# comment to trigger diff";

$files{empty_temp_config}{path} = "/var/lib/pcsd/quattor.temp.config";
$files{empty_temp_config}{txt} = "# temp config";

1;
