use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Quattor;
use Test::Quattor::Object;

use NCM::Component::Postgresql::Service qw($POSTGRESQL);

# service variant set to linux_sysv
my $mock = Test::MockModule->new('NCM::Component::Postgresql::Service');

my $obj = Test::Quattor::Object->new();

my $servicename = "$POSTGRESQL-9.2";

=head1 _initialize

Test suffix, SERVICENAME attribute and services set

=cut

is($POSTGRESQL, 'postgresql', 'exported POSTGRESQL default service name');

my $srv = NCM::Component::Postgresql::Service->new(name => $servicename, log => $obj);
isa_ok($srv, 'NCM::Component::Postgresql::Service',
       'is a NCM::Component::Postgresql::Service instance');
isa_ok($srv, 'CAF::Service', 'is a CAF::Service subclass');
is($srv->{SERVICENAME}, $servicename, 'SERVICENAME with suffix is set');
is_deeply($srv->{services}, [$servicename], 'expected services set');

is("$srv", $servicename, "stringification gives servicename");

=head2 initdb and status

Test custom initdb and status

=cut

foreach my $m (qw(start stop restart reload initdb status)) {
    diag "method $m";
    $srv->$m();
    ok(get_command("service $servicename $m"), "subclassed postgresql service $m works");
}

=head2 _wrap_in_status

=cut

# 1st el: name of last called
# 2nd: number of time ok/not is called
# 3rd: number time status was called
# 4th: return 1st status
# 5th: return 2nd status
my $called = ['', 0, 0, 0, 1];
$mock->mock('ok', sub {$called->[0] = 'ok'; $called->[1]++;});
$mock->mock('notok', sub {$called->[0] = 'notok'; $called->[1]++;});
$mock->mock('status', sub {return $called->[3+$called->[2]++];});

#
# typical for status_start
#
# service not running initially, running at the end
$called = ['', 0, 0, 0, 1];
# expected: not running initially, running at the end
is($srv->_wrap_in_status(0, 'ok', 'notok', 1), 1, '_wrap_in_status returns 1 pt1-1');
is_deeply($called, ['ok', 1, 2, 0, 1], 'called as expected pt1-1');

# service running initially, running at the end
$called = ['', 0, 0, 1, 1];
# expected: not running initially, running at the end
is($srv->_wrap_in_status(0, 'ok', 'notok', 1), 1, '_wrap_in_status returns 1 pt1-2');
is_deeply($called, ['notok', 1, 2, 1, 1], 'called as expected pt1-2');

# service not running initially, not running at the end
$called = ['', 0, 0, 0, 0];
# expected: not running initially, running at the end
is($srv->_wrap_in_status(0, 'ok', 'notok', 1), 0, '_wrap_in_status returns 0 pt1-3');
is_deeply($called, ['ok', 1, 2, 0, 0], 'called as expected pt1-3');

# service running initially, not running at the end
$called = ['', 0, 0, 1, 0];
# expected: not running initially, running at the end
is($srv->_wrap_in_status(0, 'ok', 'notok', 1), 0, '_wrap_in_status returns 0 pt1-4');
is_deeply($called, ['notok', 1, 2, 1, 0], 'called as expected pt1-4');

#
# typical for status_stop
#
# service not running initially, not running at the end
$called = ['', 0, 0, 0, 0];
# expected: not running initially, not running at the end
is($srv->_wrap_in_status(0, 'ok', 'notok', 0), 1, '_wrap_in_status returns 1 pt2-1');
is_deeply($called, ['ok', 1, 2, 0, 0], 'called as expected pt2-1');

# service running initially, not running at the end
$called = ['', 0, 0, 1, 0];
# expected: not running initially, not running at the end
is($srv->_wrap_in_status(0, 'ok', 'notok', 0), 1, '_wrap_in_status returns 1 pt2-2');
is_deeply($called, ['notok', 1, 2, 1, 0], 'called as expected pt2-2');

# service not running initially, running at the end
$called = ['', 0, 0, 0, 1];
# expected: not running initially, not running at the end
is($srv->_wrap_in_status(0, 'ok', 'notok', 0), 0, '_wrap_in_status returns 0 pt2-3');
is_deeply($called, ['ok', 1, 2, 0, 1], 'called as expected pt2-3');

# service running initially, running at the end
$called = ['', 0, 0, 1, 1];
# expected: not running initially, not running at the end
is($srv->_wrap_in_status(0, 'ok', 'notok', 0), 0, '_wrap_in_status returns 0 pt2-4');
is_deeply($called, ['notok', 1, 2, 1, 1], 'called as expected pt2-4');

#
# test undefs
#

# service not running initially, running at the end
$called = ['', 0, 0, 0, 1];
# expected: not running initially, running at the end
is($srv->_wrap_in_status(0, undef, 'notok', 1), 1, '_wrap_in_status returns 1 pt3-1');
is_deeply($called, ['', 0, 1, 0, 1], 'called as expected pt3-1');

# service running initially, running at the end
$called = ['', 0, 0, 1, 1];
# expected: not running initially, running at the end
is($srv->_wrap_in_status(0, 'ok', undef, 1), 0, '_wrap_in_status returns 1 pt3-2');
is_deeply($called, ['', 0, 1, 1, 1], 'called as expected pt3-2');

=head2 derived from _wrap_in_status

=cut

$mock->mock('_wrap_in_status', sub {shift; return \@_;});

is_deeply($srv->status_start(), [1, undef, 'start', 1],
          "status_start calls _wrap_in_status");

is_deeply($srv->status_stop(), [0, undef, 'stop', 0],
          "status_stop calls _wrap_in_status");

is_deeply($srv->status_reload(), [1, 'reload', 'start', 1],
          "status_reload calls _wrap_in_status");

is_deeply($srv->status_restart(), [1, 'restart', 'start', 1],
          "status_restart calls _wrap_in_status");

is_deeply($srv->status_initdb(), [0, 'initdb_start', 'restart', 1],
          "status_initdb calls _wrap_in_status");


my $initdb = 0;
my $start = 1;
$mock->mock('initdb', sub { return $initdb++});
$mock->mock('start', sub { return $start++});

# should be same as after running, the ++ happens after reading value to be returned
diag ' s ', $start, ' i ', $initdb, ' x ',explain ! ($initdb && $start), ' y ',explain ($initdb && $start);
ok(! ($initdb && $start), 'initdb && start is false');

ok(! $srv->initdb_start, "false initdb && start returned");
is($initdb, 1, 'initdb called');
is($start, 2, 'start called');


#
my $sysv_files = ["/etc/init.d/postgresql", "/etc/init.d/$servicename"];
my @files = $srv->installation_files_linux_sysv("postgresql");
is_deeply(\@files, $sysv_files,
          "Generated correct service files for linux_sysv");

my $sysd_files = ["/usr/lib/systemd/system/postgresql.service", "/etc/systemd/system/$servicename.service"];
@files = $srv->installation_files_linux_systemd("postgresql");
is_deeply(\@files, $sysd_files,
          "Generated correct service files for linux_systemd");

# autoload linux_sysv
@files = $srv->installation_files("postgresql");
is_deeply(\@files, $sysv_files,
          "Generated correct service files for autoloaded linux_sysv");

done_testing;
