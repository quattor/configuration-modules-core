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


my $cmp = NCM::Component::metaconfig->new('metaconfig');

$cmp->add_action("daemon1", "action1");
$cmp->add_action("daemon2", "action1");
$cmp->add_action("daemon1", "action2");

is_deeply($cmp->{_actions}, { "action1" => ["daemon1", "daemon2"], "action2" => ["daemon1"]}, 
          "Actions added");

delete $cmp->{_actions};
$cmp->prepare_action({'daemon' => ['d1', 'd2']});
is_deeply($cmp->{_actions}, {"restart" => ["d1", "d2"]}, 
            "Daemon restart actions added");

delete $cmp->{_actions};
$cmp->prepare_action({'daemon' => ['d1', 'd2'], 
                      'daemons' => {'d1' => 'reload', 
                                    'd2' => 'restart', 
                                    'd3' => 'doesnotexist'
                      }});
# d2 only once in restart
# d1 in reload and restart                      
is_deeply($cmp->{_actions}, { "restart" => ["d2", "d1"],  # restart from daemons is processed first
                              'reload' => ['d1'], 
                              'doesnotexist' => ['d3']}, 
            "Daemon restart and daemons actions added");

$cmp->process_actions();
is($restart, 2, '2 restarts triggered');
is($reload, 1, '1 reload triggered');
is($cmp->{ERROR}, 1, '1 error logged due to unsupported action');

my $cfg_d = get_config_for_profile('actions_daemons');
my $cfg_nd = get_config_for_profile('actions_nodaemons');

$restart = $reload = 0;
delete $cmp->{_actions};
is($cmp->Configure($cfg_d), 1, 'Configure actions_daemons returned 1');
is($restart, 0, '0 restarts triggered (daemons configured, no file changes)');
is($reload, 0, '0 reload triggered (daemons configured, no file changes)');

$restart = $reload = 0;
delete $cmp->{_actions};
is($cmp->Configure($cfg_nd), 1, 'Configure actions_nodaemons returned 1');
is($restart, 0, '0 restarts triggered (no daemons configured, no file changes)');
is($reload, 0, '0 reload triggered (no daemons configured, no file changes)');

# all files are changed files
$pretend_changed=1;

$restart = $reload = 0;
delete $cmp->{_actions};
is($cmp->Configure($cfg_d), 1, 'Configure actions_daemons returned 1');
is($restart, 1, '1 restarts triggered (daemons configured, file changes)');
is($reload, 1, '1 reload triggered (daemons configured, file changes)');

$restart = $reload = 0;
delete $cmp->{_actions};
is($cmp->Configure($cfg_nd), 1, 'Configure actions_nodaemons returned 1');
is($restart, 0, '0 restarts triggered (no daemons configured, file changes)');
is($reload, 0, '0 reload triggered (no daemons configured, file changes)');

done_testing();
