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

use File::Basename;
my $dirname = dirname(__FILE__);

# bunch of commands and their output
our %cmds;
our %files;

# split in files due to too long
sub _evalfn {
    my $fn = shift;
    open CODE, $fn;
    undef $\;
    my $code = join('', <CODE>);
    close CODE;
    eval $code;
    die $@ if $@;
}

my @files = qw(service-systemctl_list service-systemctl_show
               service-systemctl_daemon_reload
               service_systemctl_list_show_gen_full_el7_ceph021
               service-legacy);
foreach my $file (@files) {
    _evalfn("$dirname/cmddata/$file");
}

1;
