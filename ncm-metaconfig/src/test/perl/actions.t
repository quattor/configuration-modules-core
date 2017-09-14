use strict;
use warnings;
use Test::More tests => 22;
use Test::Quattor qw(actions_daemons actions_nodaemons);
use Test::MockModule;
use NCM::Component::metaconfig;
use CAF::Object;
use CAF::FileWriter;
use Readonly;

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

# Keep consistent with test profiles
Readonly my $FILE1_NAME => '/foo/bar';
Readonly my $FILE2_NAME => '/foo/bar2';
Readonly my $FILE1_CONTENT => '{"foo":"bar"}
';
Readonly my $FILE2_CONTENT => '{"foo":"bar"}
';

my $cfg_d = get_config_for_profile('actions_daemons');
my $cfg_nd = get_config_for_profile('actions_nodaemons');
my $fh;

$restart = $reload = 0;
set_file_contents($FILE1_NAME, $FILE1_CONTENT);
set_file_contents($FILE2_NAME, $FILE2_CONTENT);
is($cmp->Configure($cfg_d), 1, 'Configure actions_daemons returned 1');
# File contents is checked just to ensure that internal consistency is ok.
# An error here is probably the sign of an inconsistency between the unit test
# and the profiles used.
# No need to check for both $cfg_d and $cfg_nd as file contents is identical.
$fh = get_file($FILE1_NAME);
is("$fh", $FILE1_CONTENT, "$FILE1_NAME has expected contents");
$fh = get_file($FILE2_NAME);
is("$fh", $FILE2_CONTENT, "$FILE2_NAME has expected contents");
is($cmp->Configure($cfg_d), 1, 'Configure actions_daemons returned 1');
is($restart, 0, '0 restarts triggered (daemons configured, no file changes)');
is($reload, 0, '0 reload triggered (daemons configured, no file changes)');

$restart = $reload = 0;
set_file_contents($FILE1_NAME, $FILE1_CONTENT);
set_file_contents($FILE2_NAME, $FILE2_CONTENT);
is($cmp->Configure($cfg_nd), 1, 'Configure actions_nodaemons returned 1');
is($restart, 0, '0 restarts triggered (no daemons configured, no file changes)');
is($reload, 0, '0 reload triggered (no daemons configured, no file changes)');

$restart = $reload = 0;
set_file_contents($FILE1_NAME, '');
set_file_contents($FILE2_NAME, '');
is($cmp->Configure($cfg_d), 1, 'Configure actions_daemons returned 1');
# File contents is checked just to ensure that internal consistency is ok.
# An error here is probably the sign of an inconsistency between the unit test
# and the profiles used.
# No need to check for both $cfg_d and $cfg_nd as file contents is identical.
$fh = get_file($FILE1_NAME);
is("$fh", $FILE1_CONTENT, "$FILE1_NAME has expected contents");
$fh = get_file($FILE2_NAME);
is("$fh", $FILE2_CONTENT, "$FILE2_NAME has expected contents");
is($restart, 1, '1 restarts triggered (daemons configured, file changes)');
is($reload, 1, '1 reload triggered (daemons configured, file changes)');

$restart = $reload = 0;
set_file_contents($FILE1_NAME, '');
set_file_contents($FILE2_NAME, '');
is($cmp->Configure($cfg_nd), 1, 'Configure actions_nodaemons returned 1');
is($restart, 0, '0 restarts triggered (no daemons configured, file changes)');
is($reload, 0, '0 reload triggered (no daemons configured, file changes)');

done_testing();
