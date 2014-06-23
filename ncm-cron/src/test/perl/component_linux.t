# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(cron_linux);
use NCM::Component::cron;
use Test::MockModule;

$NCM::Component::cron::osname = "linux";  # Overrides $osname in NCM::Component::cron

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

# Mock LC::Check methods
our $LCCheck = Test::MockModule->new("LC::Check");
$LCCheck->mock(absence => sub ($;%) {return 1});
$LCCheck->mock(status => sub ($;%) {return 1});

my $cfg = get_config_for_profile('cron_linux');
my $cmp = NCM::Component::cron->new('cron');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $fh;
$fh = get_file("/etc/cron.d/test_default_log.ncm-cron.cron");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter default log file written");

# generic
like($fh, qr/1 2 3 4 5/m, "Check frequency");
like($fh, qr/root/m, "Check user");

# check for logging
like($fh, qr/ >> .*? 2>&1/m, "Check for log redirection in default log");

# Check smear is rounding correctly
$fh = get_file("/etc/cron.d/test_smear_max_items.ncm-cron.cron");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter smeared cron file written");

# check smear rounding boundary case
# If smear is 0 the smear code isn't used, so we have to leave room for
# something to be smeared. Hence don't check the minutes but set the other
# items to maximu.
like($fh, qr/23 31 12 6/m, "Check smear rounding");

# check the logfile if it's empty
$fh = get_file("/var/log/test_default_log.ncm-cron.log");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter default log file written");
like($fh, qr/^$/, "Check for empty log file");

$fh = get_file("/etc/cron.d/test_nolog.ncm-cron.cron");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter nolog file written");

unlike($fh, qr/ >> .*? 2>&1/m, "No log redirection when log disabled");
unlike($fh, qr/\|/m, "No redirection to pipe when log disabled");

# check for default syslog (ie pipe to logger)
$fh = get_file("/etc/cron.d/test_syslog.ncm-cron.cron");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter syslog file written");
like($fh, qr/\|.*?logger/m, "Check for pipe to logger");

# check /etc/allow
$fh = get_file("/etc/cron.allow");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter etc cron allow file written");
like($fh, qr/root/m, "Check root user in /etc/cron.allow");

done_testing();
