# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<ipmi> component.

It's a very simple component that only calls C<ipmitool> with
different parameters.

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor qw(ipmi);
use NCM::Component::ipmi;
use Readonly;

my $cfg = get_config_for_profile("ipmi");
my $cmp = NCM::Component::ipmi->new("ipmi");

Readonly my $CMD => NCM::Component::ipmi::IPMI_EXEC;

$cmp->Configure($cfg);

my $cmd = get_command(join(" ", $CMD,
                           qw(user set name), "userid", "login"));
ok(defined($cmd), "ipmitool user set name was called");
$cmd = get_command(join(" ", $CMD, qw(mc reset cold)));

ok(defined($cmd), "mc is reset inconditionally");

done_testing();
