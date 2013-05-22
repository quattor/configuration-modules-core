# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(simple_services);
use NCM::Component::chkconfig;


$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

my $cfg = get_config_for_profile('simple_services');
my $cmp = NCM::Component::chkconfig->new('chkconfig');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $cmd;

$cmd = get_command("/sbin/chkconfig --level 1 test_on on");
isa_ok($cmd, "CAF::Process", "Command for service test_on on run");

$cmd = get_command("/sbin/chkconfig --level 1 othername on");
isa_ok($cmd, "CAF::Process", "Command for service test_on_rename on run");

done_testing();
