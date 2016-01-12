use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Quattor;
use Test::Quattor::Object;

use NCM::Component::Postgresql::Commands;

use Readonly;

Readonly my $POSTGRESQL_USER => 'postgres';
Readonly my $PROCESS_LOG_ENABLED => 'PROCESS_LOG_ENABLED';

my $mock = Test::MockModule->new('NCM::Component::Postgresql::Commands');

my $expected_fn = '/not/a/file';
$mock->mock('_file_exists', sub {
    shift;
    my $filename = shift;
    return $filename eq $expected_fn;
});

my $obj = Test::Quattor::Object->new();

=head1 _initialize

Test engine, su and PROCESS_LOG_ENABLED atributes

=cut

$expected_fn = '/not/runuser';

my $engine = 'myengine/dir';

my $cmds = NCM::Component::Postgresql::Commands->new($engine, log => $obj);
isa_ok($cmds, 'NCM::Component::Postgresql::Commands',
       'got a NCM::Component::Postgresql::Commands instance');
isa_ok($cmds, 'CAF::Object', 'cmd is also a CAF::Object instance');

is($cmds->{engine}, $engine, "engine attribute set");
is($cmds->{su}, '/bin/su', "su is the su method when runuser not found");
is($cmds->{$PROCESS_LOG_ENABLED}, 1, 'PROCESS_LOG_ENABLED enabled after init');


$expected_fn = '/sbin/runuser';
my $cmds_ru = NCM::Component::Postgresql::Commands->new(undef, log => $obj);
isa_ok($cmds_ru, 'NCM::Component::Postgresql::Commands',
       'got a NCM::Component::Postgresql::Commands instance');
is($cmds_ru->{su}, '/sbin/runuser', "runser is the su method when runuser found");
is($cmds_ru->{engine}, '/no/engine/defined', "engine attribute set to non-existing value is not defined");

=head1 run_postgres

=cut

# no quotes around 'a b c', but should be subshell'ed
my $test_cmd = '/bin/su -l postgres -c a b c';
my @logs;

set_desired_output($test_cmd, 'ran fine');
set_command_status($test_cmd, 0); # shell exitcode
$obj->loghist_reset();
is($cmds->run_postgres(['a', 'b', 'c']),
   'ran fine',
   'Command ran and expected output');

# one message logged verbose
@logs = $obj->loghist_get('VERBOSE');
like($logs[0], qr{^Command /bin/su -l postgres -c a b c exitcode 0 output ran fine$},
     'verbose message logged with test run_postgres');
ok(! defined($obj->loghist_get('ERROR')), 'no error logged with test run_postgres');

$cmds->{$PROCESS_LOG_ENABLED} = 0;
$obj->loghist_reset();
set_desired_output($test_cmd, 'ran fine no logging');
is($cmds->run_postgres(['a', 'b', 'c']),
   'ran fine no logging',
   'Command ran and expected output (pt 2, log disabled)');
ok(! defined($obj->loghist_get('VERBOSE')), 'no verbose message logged with test run_postgres (pt2, log disabled)');
ok(! defined($obj->loghist_get('ERROR')), 'no error logged with test run_postgres (pt2, log disabled)');

# test failures
$cmds->{$PROCESS_LOG_ENABLED} = 1;

set_command_status($test_cmd, 1);
$obj->loghist_reset();
set_desired_output($test_cmd, 'failed to run');
ok(! defined($cmds->run_postgres(['a', 'b', 'c'])),
   'Failed command returned undef');
ok(! defined($obj->loghist_get('VERBOSE')), 'no verbose logged with failed test run_postgres');
@logs = $obj->loghist_get('ERROR');
like($logs[0], qr{^Command /bin/su -l postgres -c a b c exitcode 1 output failed to run$},
     'error message logged with failed test run_postgres');

$cmds->{$PROCESS_LOG_ENABLED} = 0;
$obj->loghist_reset();
set_desired_output($test_cmd, 'failed to run no logging');
ok(! defined($cmds->run_postgres(['a', 'b', 'c'])),
   'Failed command returned undef (pt 2, log disabled)');
ok(! defined($obj->loghist_get('VERBOSE')),
   'no verbose message logged with test run_postgres (pt2, log disabled)');
ok(! defined($obj->loghist_get('ERROR')),
   'no error logged with test run_postgres (pt2, log disabled)');

# reenabled logging by default
$cmds->{$PROCESS_LOG_ENABLED} = 1;

=head1 run_pgsql

=cut

$obj->loghist_reset();
ok(! defined($cmds->run_psql([qw(select from something; and then some)])),
   'psql args with ; return undef');
@logs = $obj->loghist_get('ERROR');
like($logs[0], qr{^psql args cannot contain a ';' \(sql: select from something; and then some\)$},
     'error message logged with failed test run_postgres');

# no sql when logging disabled
$cmds->{$PROCESS_LOG_ENABLED} = 0;
$obj->loghist_reset();
ok(! defined($cmds->run_psql([qw(select from something; and then some no logging)])),
   'psql args with ; return undef no logging');
@logs = $obj->loghist_get('ERROR');
like($logs[0], qr{^psql args cannot contain a ';'$},
     'error message logged with failed test run_postgres no logging');
# restore
$cmds->{$PROCESS_LOG_ENABLED} = 1;


# escaped ", added ;
$test_cmd = "/bin/su -l postgres -c $engine/psql -t -c \"select \\\"a\\\" from b;\"";
set_desired_output($test_cmd, 'psql ran fine');
set_command_status($test_cmd, 0); # shell exitcode
is($cmds->run_psql([qw(select "a" from b)]),
   'psql ran fine',
   'psql ran expected postgres command');

=head1 simple_select

=cut

my $outputdata = <<EOF;
  col1
  col2
  col3


EOF

$test_cmd = "/bin/su -l postgres -c $engine/psql -t -c \"SELECT a FROM b;\"";
set_desired_output($test_cmd, $outputdata);
set_command_status($test_cmd, 0); # shell exitcode

is_deeply($cmds->simple_select('a', 'b'),
          [qw(col1 col2 col3)],
          "Simpe select returned array ref of results");

=head1 get_roles / create_role / alter_role

=cut

my @pgargs;
$mock->mock('run_postgres', sub {
    shift;
    @pgargs = @{shift()};
    return 1;
});
my @psql;
my $psql_res = 1;
my $psql_log_enabled;
$mock->mock('run_psql', sub {
    my $self = shift;
    $psql_log_enabled = $self->{$PROCESS_LOG_ENABLED};
    @psql = @{shift()};
    return $psql_res;
});
my @simpleselect;
$mock->mock('simple_select', sub {
    shift;
    @simpleselect = @_;
    return 1;
});

@simpleselect = ();
ok($cmds->get_roles(), 'get_roles returns success');
is_deeply(\@simpleselect, [qw(rolname pg_roles)], 'get_roles calls simple_select as expected');

@psql = ();
ok($cmds->create_role('myrole'), 'create_role returns success');
# role gets quoted
is_deeply(\@psql, [qw(CREATE ROLE "myrole")],
          'create_role calls run_psql as expected');


# set  it to 2 to track restore
$psql_log_enabled = undef;
$cmds->{$PROCESS_LOG_ENABLED} = 2;
$obj->loghist_reset();
ok($cmds->alter_role('myrole', 'some sql'), 'alter_role success');
is($cmds->{$PROCESS_LOG_ENABLED}, 2, 'old PROCESS_LOG_ENABLED restored');
is($psql_log_enabled, 0, 'psql ran alter_role with PROCESS_LOG_ENABLED=0');
@logs = $obj->loghist_get('VERBOSE');
like($logs[0], qr{^Altered role myrole.$},
     'verbose message logged with test alter_role');
ok(! defined($obj->loghist_get('ERROR')), 'no error logged with test alter_role');

$psql_res = undef;
$obj->loghist_reset();
ok(! defined($cmds->alter_role('myrolefail', 'some sql fail')), 'failed alter_role returns undef');
ok(! defined($obj->loghist_get('VERBOSE')), 'no verbose logged with failed test alter_role');
@logs = $obj->loghist_get('ERROR');
like($logs[0], qr{^Failed to alter role myrolefail.$},
     'error message logged with failed test alter_role');

# restore
$psql_log_enabled = 1;
$psql_res = 1;

=head1 get_databases / create_database / create_database_lang

=cut

@simpleselect = ();
ok($cmds->get_databases(), 'get_databases returns success');
is_deeply(\@simpleselect, [qw(datname pg_database)], 'get_databases calls simple_select as expected');

@psql = ();
ok($cmds->create_database('mydatabase', 'myowner'), 'create_database returns success');
is_deeply(\@psql, [qw(CREATE DATABASE "mydatabase" OWNER "myowner")],
          "create_database calls run_psql as expected");

@pgargs = ();
ok($cmds->create_database_lang('mydatabase2', 'mylang'), 'create_database_lang returns success');
is_deeply(\@pgargs, ["$engine/createlang", "mydatabase2", "mylang"],
          'create_database_lang calls run_postgres as expected');

$expected_fn = 'some/filename';
@pgargs = ();
ok($cmds->run_commands_from_file('mydatabase3', 'asuser', 'some/filename'),
   'run_commands_from_file returns success');
is_deeply(\@pgargs, ["$engine/psql", "-U", "asuser", "-f", "some/filename", "mydatabase3"],
          'run_commands_from_file calls run_postgres as expected');

$expected_fn = 'not/a/file';
ok(! defined($cmds->run_commands_from_file('mydatabase4', 'asuser2', 'some/filename')),
   'run_commands_from_file returns undef with non-existing file');


done_testing();
