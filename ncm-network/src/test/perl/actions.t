# -*- mode: cperl -*-
use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(actions);
use Test::MockModule;

use NCM::Component::network;


my $mock = Test::MockModule->new('CAF::Service');

our ($restart, $reload, $stop_sleep_start) = qw(0 0 0);

$mock->mock('restart', sub {
    my $self = shift;
    $restart += scalar @{$self->{services}};
});
$mock->mock('reload', sub {
    my $self = shift;
    $reload += scalar @{$self->{services}};
});
$mock->mock('stop_sleep_start', sub {
    my $self = shift;
    $stop_sleep_start += scalar @{$self->{services}};
});


my $cfg = get_config_for_profile('actions');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with daemon actions set");

is($restart, 1, "$restart/1 restarts triggered");
is($reload, 2, "$reload/2 reloads triggered");
is($stop_sleep_start, 3, "$stop_sleep_start/3 stop_sleep_starts triggered");

done_testing();
