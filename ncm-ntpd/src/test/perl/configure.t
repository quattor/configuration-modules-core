# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(no_timeservers only_timeservers only_timeservers_useserverip simple_serverlist disable_options group);
use NCM::Component::ntpd;
use CAF::Object;
use Test::MockModule;
use Test::Quattor::RegexpTest;

$CAF::Object::NoAction = 1;

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

my $cmd = get_command("service ntpd restart");
ok( !$cmd, "Daemon was not restarted when nothing changes" );

# pretend there are changes to ntp.conf.
$mock->mock('needs_restarting', 1);

$cfg = get_config_for_profile('only_timeservers');
is( $cmp->Configure($cfg), 1, "Component runs correctly with only_timeservers profile" );

my $fh = get_file($NCM::Component::ntpd::NTPDCONF);
isa_ok($fh, "CAF::FileWriter", "This is a CAF::FileWriter file written");
Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/regexps/only_timeservers',
    text => "$fh",
    )->test();

# set useserverip
$cfg = get_config_for_profile('only_timeservers_useserverip');
is( $cmp->Configure($cfg), 1, "Component runs correctly with only_timeservers_useserverip profile" );
$fh = get_file($NCM::Component::ntpd::NTPDCONF);
isa_ok($fh, "CAF::FileWriter", "This is a CAF::FileWriter file written");
Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/regexps/only_timeservers_useserverip',
    text => "$fh",
    )->test();



my $stfh = get_file($NCM::Component::ntpd::STEPTICKERS);
isa_ok($stfh, "CAF::FileWriter", "This is a CAF::FileWriter file written");
like($stfh, qr{^\b(?:\d{1,3}\.){3}\d{1,3}\b}m, "Has a timeserver in ntp steptickers file");

my $defopts = {
   'backup' => '.old',
   'mode' => 0644,
   'noaction' => 1, # This is from running in unittest environment
};
is_deeply(*$fh->{options}, $defopts, 'ntp.conf has expected default mode setting without group defined');
is_deeply(*$stfh->{options}, $defopts, 'steptickers has expected default mode setting without group defined');


$cmd = get_command("service ntpd restart");
ok( $cmd, "Daemon was restarted with only_timeservers profile" );

$cfg = get_config_for_profile('simple_serverlist');
is( $cmp->Configure($cfg), 1, "Component runs correctly with simple_serverlist profile" );

$cmd = get_command("service ntpd restart");
ok( $cmd, "Daemon was restarted with simple_serverlist profile" );

$cfg = get_config_for_profile('disable_options');
is( $cmp->Configure($cfg), 1, "Component runs correctly with disable_options profile" );

$fh = get_file($NCM::Component::ntpd::NTPDCONF);
isa_ok($fh, "CAF::FileWriter", "This is a CAF::FileWriter file written");
like($fh, qr/^disable\s+monitor/m, "Has monitor option disabled");

# Test group restricted filepermissions

$cmd = get_command("service ntpd restart");
ok( $cmd, "Daemon was restarted with simple_serverlist profile" );

$cfg = get_config_for_profile('group');
is( $cmp->Configure($cfg), 1, "Component runs correctly with group profile" );

my $opts = {
   'owner' => 'root',
   'group' => 'ntp',
   'backup' => '.old',
   'mode' => 0640,
   'noaction' => 1, # This is from running in unittest environment
};

$fh = get_file($NCM::Component::ntpd::NTPDCONF);
is_deeply(*$fh->{options}, $opts, 'ntp.conf has expected owner/group/perm settings with group defined');

$stfh = get_file($NCM::Component::ntpd::STEPTICKERS);
is_deeply(*$stfh->{options}, $opts, 'steptickers has expected owner/group/perm settings with group defined');

done_testing();
