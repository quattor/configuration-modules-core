# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<process_install> method.

This method is identical to C<process_options> and
C<process_remove>.  It's enough to test this one.

=cut

use strict;
use warnings;
use Test::More tests => 2;
use Test::Quattor;
use CAF::FileWriter;
use NCM::Component::modprobe;
use CAF::Object;
use Readonly;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::modprobe->new("modprobe");

my $fh = CAF::FileWriter->new("target/modprobe_process_install");

Readonly::Hash my %TREE => (modules => [
        {
            install => "module_command",
            name => "module_name1",
        },
        {
            name => "module_name2",
        },
    ],
);

$cmp->process_install(\%TREE, $fh);

like($fh, qr{^install\s+module_name1\s+module_command$}m,
     "First install line rendered correctly");
unlike($fh, qr{module_name2$}m, "Module without command not printed");

$fh->close();
