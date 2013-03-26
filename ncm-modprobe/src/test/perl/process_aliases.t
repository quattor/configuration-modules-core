# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<process_alias> method.

This method is identical to C<process_install>, C<process_options> and
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

my $fh = CAF::FileWriter->new("/etc/modprobe.d");

Readonly::Hash my %TREE => (modules => [
        {
                alias => "module_alias1",
                name => "module_name1"
               },
        {
                name => "module_name2",
        },
       ]
                           );

$cmp->process_alias(\%TREE, $fh);

like($fh, qr{^alias\s+module_alias1\s+module_name1$}m,
     "First alias line rendered correctly");
unlike($fh, qr{module_name2$}m, "Module without aliases not printed");
