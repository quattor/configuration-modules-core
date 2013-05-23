# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(simple_services);
use NCM::Component::chkconfig;
use Readonly;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

Readonly my $CHKCONFIG_LIST_OUTPUT => <<EOF;
test_on            0:off   1:off   2:off   3:off   4:off   5:off   6:off
othername          0:off   1:off   2:off   3:off   4:off   5:off   6:off
test_off           0:off   1:off   2:off   3:off   4:on    5:off   6:off
test_del           0:off   1:off   2:off   3:off   4:off   5:off   6:off
EOF

set_desired_output("/sbin/chkconfig --list",$CHKCONFIG_LIST_OUTPUT);

set_desired_output("/sbin/runlevel","N 5");

my $cfg = get_config_for_profile('simple_services');
my $cmp = NCM::Component::chkconfig->new('chkconfig');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $cmd;

# service add (test_add also tests unescaping of getTree)
# test_add should not exist in $chkconfig_list_output
$cmd = get_command("/sbin/chkconfig --add test_add")->{object};
isa_ok($cmd, "CAF::Process", "Command for service --add test_add run");

# service on
$cmd = get_command("/sbin/chkconfig test_on off")->{object};
isa_ok($cmd, "CAF::Process", "Command for service test_on on (off first) run");
$cmd = get_command("/sbin/chkconfig --level 123 test_on on")->{object};
isa_ok($cmd, "CAF::Process", "Command for service test_on on run");

# service on with renamed service
$cmd = get_command("/sbin/chkconfig othername off")->{object};
isa_ok($cmd, "CAF::Process", "Command for service test_on_rename on (off first) run");
$cmd = get_command("/sbin/chkconfig --level 4 othername on")->{object};
isa_ok($cmd, "CAF::Process", "Command for service test_on_rename on run");


# to test del and/or off, the service needs to be there and
# turned on for at least one of the selected runlevels.
$cmd = get_command("/sbin/chkconfig --level 45 test_off off")->{object};
isa_ok($cmd, "CAF::Process", "Command for service test_off off run");

$cmd = get_command("/sbin/chkconfig test_del off")->{object};
isa_ok($cmd, "CAF::Process", "Command for service --del test_del (off first) run");
$cmd = get_command("/sbin/chkconfig --del test_del")->{object};
isa_ok($cmd, "CAF::Process", "Command for service --del test_del run");


done_testing();
