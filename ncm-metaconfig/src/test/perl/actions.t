#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(actions_daemons actions_nodaemons);
use Test::MockModule;
use NCM::Component::metaconfig;
use CAF::Object;
use CAF::FileWriter;

$CAF::Object::NoAction = 1;

my $mock = Test::MockModule->new('CAF::Service');
our ($restart, $reload);
$mock->mock('restart', sub {
    my $self = shift;
    $restart += scalar @{$self->{services}}; 
});
$mock->mock('reload', sub {
    my $self = shift;
    $reload += scalar @{$self->{services}}; 
});

my $pretend_changed;

no warnings 'redefine';
*CAF::FileWriter::close = sub {
    return $pretend_changed;
};
use warnings 'redefine';

=pod

=head1 DESCRIPTION

Test how the need for restarting a service is handled

=cut


my $actions = {};
my $cmp = NCM::Component::metaconfig->new('metaconfig');

=pod

=head2 Test prepare_action

Test the update of the actions reference for single service

=cut

$actions = {};
$cmp->prepare_action({'daemon' => ['d1', 'd2']}, "myfile", $actions);
is_deeply($actions, {"restart" => {"d1" => 1, "d2" => 1}}, 
            "Daemon restart actions added");

$actions = {};
$cmp->prepare_action({'daemon' => ['d1', 'd2'], 
                      'daemons' => {'d1' => 'reload', 
                                    'd2' => 'restart', 
                                    'd3' => 'doesnotexist'
                                    }
                      }, "myfile", $actions);
# d2 only once in restart
# d1 in reload and restart
# doesnotexist is not allowed
is_deeply($actions, { "restart" => { "d2" => 1, "d1" => 1}, 
                      'reload' => {'d1' => 1 }
                    }, "Daemon restart and daemons actions added");

is($cmp->{ERROR}, 1, '1 error logged due to unsupported action');

=pod

=head2 Test process_action

Test taking actions based on the actions reference

=cut

$cmp->process_actions($actions);
is($restart, 2, '2 restarts triggered');
is($reload, 1, '1 reload triggered');

=pod

=head2 Test actions taken via Configure

Test taking actions by whole Configure method

=cut


my $cfg_d = get_config_for_profile('actions_daemons');
my $cfg_nd = get_config_for_profile('actions_nodaemons');

$restart = $reload = 0;
is($cmp->Configure($cfg_d), 1, 'Configure actions_daemons returned 1');
is($restart, 0, '0 restarts triggered (daemons configured, no file changes)');
is($reload, 0, '0 reload triggered (daemons configured, no file changes)');

$restart = $reload = 0;
is($cmp->Configure($cfg_nd), 1, 'Configure actions_nodaemons returned 1');
is($restart, 0, '0 restarts triggered (no daemons configured, no file changes)');
is($reload, 0, '0 reload triggered (no daemons configured, no file changes)');

# all files are changed files
$pretend_changed=1;

$restart = $reload = 0;
is($cmp->Configure($cfg_d), 1, 'Configure actions_daemons returned 1');
is($restart, 1, '1 restarts triggered (daemons configured, file changes)');
is($reload, 1, '1 reload triggered (daemons configured, file changes)');

$restart = $reload = 0;
is($cmp->Configure($cfg_nd), 1, 'Configure actions_nodaemons returned 1');
is($restart, 0, '0 restarts triggered (no daemons configured, file changes)');
is($reload, 0, '0 reload triggered (no daemons configured, file changes)');

done_testing();
