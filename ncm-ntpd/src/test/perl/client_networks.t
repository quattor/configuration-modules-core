# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(client_networks);
use NCM::Component::ntpd;
use CAF::Object;
use Test::MockModule;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the ability to add client networks to the configuration.

=cut

my $mock = Test::MockModule->new('NCM::Component::ntpd');
my $cmp = NCM::Component::ntpd->new('ntpd');
my $cfg = get_config_for_profile('client_networks');

# pretend there are changes to /etc/ntp.conf
$mock->mock('needs_restarting', 1);

is( $cmp->Configure($cfg), 1, 'Component runs correctly with client_networks profile' );
my $fh = get_file($NCM::Component::ntpd::NTPDCONF);
isa_ok($fh, 'CAF::FileWriter', 'File is handled by CAF::FileWriter');
like($fh, qr/^restrict\s+10\.0\.0\.0\s+mask\s+255\.0\.0\.0\s+nomodify\s+notrap/m, 'First client network found');
like($fh, qr/^restrict\s+172\.16\.0\.0\s+mask\s+255\.240\.0\.0\s+nomodify\s+notrap/m, 'Second client network found');
like($fh, qr/^restrict\s+192\.168\.0\.0\s+mask\s+255\.255\.0\.0\s+nomodify\s+notrap/m, 'Third client network found');
my $cmd = get_command('service ntpd restart');
ok($cmd, 'Daemon was restarted with client_networks profile');

done_testing();
