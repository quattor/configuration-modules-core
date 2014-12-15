use strict;
use warnings;
use Test::More;
use Test::Quattor qw(icinga_simple);

use myIcinga;

my $cmp = NCM::Component::icinga->new('icinga');

my %methods = (
    make_dirs                 => 0,
    print_general             => 0,
    print_cgi                 => 0,
    print_macros              => 0,
    print_hosts               => 0,
    print_hosts_generic       => 0,
    print_hostgroups          => 0,
    print_commands            => 0,
    print_services            => 0,
    print_servicedependencies => 0,
    print_contacts            => 0,
    print_serviceextinfo      => 0,
    print_hostdependencies    => 0,
    print_other               => 0,
    print_ido2db_config       => 0
);

no strict 'refs';
no warnings 'redefine';

foreach my $m (keys(%methods)) {
    *{"NCM::Component::icinga::$m"} = sub {$methods{$m}++;};
}

use strict 'refs';
use warnings 'redefine';

my $cfg = get_config_for_profile('icinga_simple');

ok($cmp->Configure($cfg), "Icinga component run successfully");

while (my ($method, $called) = each(%methods)) {
    is($called, 1, "Method $method was called exactly once");
}

is($?, 0, "Icinga command was correctly run");
set_command_status("service icinga restart", 1);

ok(!$cmp->Configure($cfg), "Icinga component didn't run successfully");
is($cmp->{ERROR}, 1, "Error was reported");

is($?, 1, "Icinga command failed");

done_testing();
