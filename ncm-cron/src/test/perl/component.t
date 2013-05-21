# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(cron_syslog);
use File::Path qw(mkpath);
use NCM::Component::cron;
use Test::MockModule;


$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

my $cfg = get_config_for_profile('');
my $cmp = NCM::Component::cron->new('cron');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $fh = get_file("/etc/cron.d/test_default_log.ncm-cron.cron");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter default log file written");

# generic
like($fh, qr/1 2 3 4 5/m, "Check frequency");
like($fh, qr/myspecialroot/m, "Check user");

# check for logging
like($fh, qr/ >> .*? 2>&1/m, "Check for log redirection in default log");

my $fh = get_file("/etc/cron.d/test_nolog.ncm-cron.cron");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter nolog file written");

unlike($fh, qr/ >> .*? 2>&1/m, "No log redirection when log disabled");
unlike($fh, qr/\|/m, "No redirection to pipe when log disabled");


# check for default syslog (ie pipe to logger)
my $fh = get_file("/etc/cron.d/test_syslog.ncm-cron.cron");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter syslog file written");
like($fh, qr/\|.*?logger/m, "Check for pipe to logger");

done_testing();
