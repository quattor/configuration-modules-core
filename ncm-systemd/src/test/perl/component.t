# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(component);
use NCM::Component::systemd;
use helper;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut


set_output("runlevel_5");
set_output("chkconfig_list_test");

my $cfg = get_config_for_profile('component');
my $cmp = NCM::Component::systemd->new('systemd');

is_deeply($cmp->skip($cfg),
          { service => 0 },
          "Expected hashref of what configuration to skip");

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

done_testing();
