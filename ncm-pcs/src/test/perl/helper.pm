# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

=pod

=head1 helper module

A helper module that gives runs common checks
and provides set_output, a wrapper around the data in the cmddata module and the
set_desired_output, set_desired_err and set_command_status functions.

=cut

package helper;

use strict;
use warnings;
use base 'Exporter';
use Test::MockModule;
our @EXPORT = qw(set_output set_file);

use Test::More;
use Test::Quattor;

use cmddata;

sub set_output {
    my $cmdshort = shift;
    my $cmdline = $cmddata::cmds{$cmdshort}{cmd}|| die "Undefined cmd for cmdshort $cmdshort";
    my $out = $cmddata::cmds{$cmdshort}{out} || "";
    my $err = $cmddata::cmds{$cmdshort}{err} || "";
    my $ec = $cmddata::cmds{$cmdshort}{ec} || 0;
    set_desired_output($cmdline, $out);
    set_desired_err($cmdline, $err);
    set_command_status($cmdline, $ec);
};

# 2nd argument redefines the txt
sub set_file {
    my $fileshort = shift;
    my $txt = shift || $cmddata::files{$fileshort}{txt} || die "Undefined txt for fileshort $fileshort";
    my $path = $cmddata::files{$fileshort}{path}|| die "Undefined path for fileshort $fileshort";
    set_file_contents($path, $txt);
};

1;
