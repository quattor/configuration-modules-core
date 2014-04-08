# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(no_timeservers only_timeservers simple_serverlist);
use NCM::Component::ntpd;
use CAF::Object;
use Test::MockModule;

$CAF::Object::NoAction = 1;
$LC::Check::NoAction = 1;
$NCM::Component::ntpd::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.  Ensure the methods are
called when they have configurations associated, and that the daemon
is restarted when needed.

=cut

my $mock = Test::MockModule->new('NCM::Component::ntpd');
my $cmp = NCM::Component::ntpd->new('ntpd');
my $cfg;

$cfg = get_config_for_profile('no_timeservers');
is( $cmp->Configure($cfg), 0, "time servers are required to configure" );

my $cmd = get_command("/sbin/service ntpd restart");
ok( !$cmd, "Daemon was not restarted when nothing changes" );

$cfg = get_config_for_profile('only_timeservers');
is( $cmp->Configure($cfg), 1, "Component runs correctly with only_timeservers profile" );

$cfg = get_config_for_profile('simple_serverlist');
is( $cmp->Configure($cfg), 1, "Component runs correctly with simple_serverlist profile" );

done_testing();
