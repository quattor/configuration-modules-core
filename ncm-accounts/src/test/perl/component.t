#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(users/consistent);
use NCM::Component::accounts;
use Test::MockModule;
use CAF::Object;


=pod

=head1 DESCRIPTION

Test that the Configure method does the correct things.

Instead of producing zillions of fake profiles, we'll replace by stubs
all methods called by C<Configure>.

What we want to test is:

=cut

my $mock = Test::MockModule->new("NCM::Component::accounts");

foreach my $i (qw(compute_desired_accounts compute_root_user
		  adjust_groups adjust_accounts is_consistent commit_configuration
		  build_system_map)) {
    $mock->mock($i, sub {
		    my $self = shift;
		    $self->{called}->{$i} = 1;
		    return $self->{returns}->{$i};
		});
}

my $cmp = NCM::Component::accounts->new('accounts');

my $cfg = get_config_for_profile('users/consistent');

$cmp->{returns}->{compute_desired_accounts} = {};
$cmp->{returns}->{compute_root_user} = {};
$cmp->{returns}->{is_consistent} = 0;
$cmp->{returns}->{build_system_map} = {};

=pod

=over

=item Inconsistent states will not be committed

=cut

is($cmp->Configure($cfg), 0, "Inconsistent state would raise errors");
ok(!$cmp->{called}->{commit_configuration}, "Inconsistent configuration was not committed");

=pod

=item Initialisations and in-memory maps are always generated

=cut

foreach my $i (qw(compute_desired_accounts compute_root_user
		  adjust_groups adjust_accounts is_consistent
		  build_system_map)) {
    ok($cmp->{called}->{$i}, "Activity $i was invoked");
    $cmp->{called}->{$i} = 0;
}

$cmp->{returns}->{is_consistent} = 1;

=pod

=item Consistent states get committed

=cut

is($cmp->Configure($cfg), 1, "Consistent state means successful execution");
foreach my $i (qw(compute_desired_accounts compute_root_user
		  adjust_groups adjust_accounts is_consistent
		  build_system_map commit_configuration)) {
    ok($cmp->{called}->{$i}, "Activity $i was invoked");
    $cmp->{called}->{$i} = 0;
}


done_testing();
