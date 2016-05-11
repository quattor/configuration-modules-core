# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<process_blacklist> method.

=cut

use strict;
use warnings;
use Test::More tests => 3;
use Test::Quattor;
use CAF::FileWriter;
use NCM::Component::modprobe;
use CAF::Object;
use Readonly;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::modprobe->new("modprobe");

my $fh = CAF::FileWriter->new("target/modprobe_process_blacklist");

Readonly::Hash my %TREE => (modules => [
        {
            blacklist => "",
            name => "module_name1",
        },
        {
            blacklist => "module_string",
            name => "module_name2",
        },
    ],
);

$cmp->process_blacklist(\%TREE, $fh);

like($fh, qr{^blacklist\s+module_name1$}m,
     "First blacklist line rendered correctly");
like($fh, qr{^blacklist\s+module_name2$}m,
     "Second blacklist line rendered correctly");
unlike($fh, qr{module_string$}m, "Module string correctly ignored");

$fh->close();
