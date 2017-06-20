# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(rdma);
use NCM::Component::ofed;
use Test::Quattor::RegexpTest;

use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();


=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

my $cfg = get_config_for_profile('rdma');
my $cmp = NCM::Component::ofed->new('ofed');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $fh;
$fh = get_file("/etc/rdma/rdma.conf");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter rdma.conf file written");

# generic
unlike($fh, qr/^SRP_DAEMON_ENABLE_LOAD/m, "No suffix for options");
like($fh, qr/^SRP_DAEMON_ENABLE=(yes|no)/m, "Boolean options");

like($fh, qr/^MLX4_LOAD=(yes|no)/m, "Suffix for hardware, boolean value");
like($fh, qr/^RDMA_CM_LOAD=(yes|no)/m, "Suffix for modules, boolean value");

diag "$fh";
# Test all values
my $rt = Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/rdma_regextest',
    text => "$fh",
    );
$rt->test();

$fh = get_file("/etc/opensm/partitions.conf");
is("$fh", "default=0x7fff : ALL;\n", "partitions.conf created");
$fh = get_file("/etc/opensm/ib-node-name-map");
is("$fh", "0x0123456789abcdef \"some hca\"\n", "node name map created");

ok(command_history_ok(['service opensmd restart']),
   "change in partitions.conf triggered restart in opensmd");

done_testing();
