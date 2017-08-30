use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Quattor qw(iam);
use CAF::Object;
use NCM::Component::postgresql;

use Test::Quattor::TextRender::Base;

$CAF::Object::NoAction = 1;

my $caf_trd = mock_textrender();

# service variant set to linux_sysv

my $cmp = NCM::Component::postgresql->new("postgresql");
my $cfg = get_config_for_profile('iam');

my $engine = '/usr/pgsql-9.2/bin';

my $mock = Test::MockModule->new('NCM::Component::postgresql');

my $expected_fns = [qw(/not/a/file)];
$mock->mock('_file_exists', sub {
    shift;
    my $filename = shift;
    return grep {$_ eq $filename} @$expected_fns;
});

=head1 version

=cut

set_desired_output('/usr/pgsql-9.2/bin/postmaster --version', "postgres (PostgreSQL) 9.2.13\n");
is_deeply($cmp->version($engine), [9, 2, 13], "Got correct version array ref");

set_desired_output('/my/usr/pgsql-9.2/bin/postmaster --version', "postgres (PostgreSQL) 9.2.abc\n");
ok(! defined($cmp->version("/my$engine")), "version returns undef on unparsable output");

=head1 fetch

=cut
my $pref = $cmp->prefix();
is($cmp->fetch($cfg, "$pref/doesnotexist"), "",
   "fetch returns default empty string when no default value is specified and path does not exist");
is($cmp->fetch($cfg, "$pref/doesnotexist2", "somedefault"), "somedefault",
   "fetch returns default value is path does not exist");

ok($cfg->elementExists("$pref/pg_engine"), "$pref/pg_engine element exists");
is($cfg->getValue("$pref/pg_engine"), $engine, "$pref/pg_engine has expected value");

is($cmp->fetch($cfg, "$pref/pg_engine", "somedefault"), $engine,
   "fetch returns value and not default if path exists");
is($cmp->fetch($cfg, "pg_engine", "somedefault"), $engine,
   "fetch returns value and not default when relative path is defined (relative to prefix)");


is($cmp->fetch($cfg, undef, "somedefaultundef"), "somedefaultundef",
   "fetch returns default when path is undefined");


=head1 whoami

=cut

my $iam = $cmp->whoami($cfg);

is_deeply($iam->{pg}, {
    'data' => '/var/lib/pgsql/myversion/data',
    'dir' => '/var/lib/pgsql/myversion',
    'engine' => '/usr/pgsql-9.2/bin',
    'log' => '/var/lib/pgsql/myversion/pgstartup.log',
    'port' => '2345',
}, "iam expected pg attribute");

is_deeply($iam->{version}, [9,2,13], "version via postmaster --version set");
is($iam->{servicename}, 'myownpostgresql', 'servicename set');
is($iam->{suffix}, '-1.2.3', 'suffix from cfg version');
is($iam->{defaultname}, 'postgresql-1.2.3', 'iam correct defaultname');
is($iam->{exesuffix}, '123', 'iam correct exesuffix');

isa_ok($iam->{commands}, 'NCM::Component::Postgresql::Commands',
       'iam commands attribute is a NCM::Component::Postgresql::Commands instance');
is($iam->{commands}->{engine}, $engine,
   'NCM::Component::Postgresql::Commands with correct engine');
ok($iam->{commands}->{log}, 'commands has log attribute');

isa_ok($iam->{service}, 'NCM::Component::Postgresql::Service',
       'iam service is a NCM::Component::Postgresql::Service instance');
is($iam->{service}->{SERVICENAME}, 'myownpostgresql',
   'iam service has correct SERVICENAME');
ok($iam->{service}->{log}, 'iam services has log attribute');

my ($svc_def_fn, $svc_fn) = $iam->{service}->installation_files($iam->{defaultname});
is($svc_def_fn, '/etc/init.d/postgresql-1.2.3', 'default service filename returned');
is($svc_fn, '/etc/init.d/myownpostgresql', 'service filename returned');

=head1 prepare_service

=cut

$expected_fns = [$svc_fn];
ok(! defined($cmp->prepare_service($iam)), 'prepare_service returns undef if default service name is missing');

$expected_fns = [$svc_def_fn];
ok(! defined($cmp->prepare_service($iam)), 'prepare_service returns undef if actual service name is missing');

$expected_fns = [$svc_def_fn, $svc_fn];
my $sys_changed = $cmp->prepare_service($iam);

my $sys_fn = '/etc/sysconfig/pgsql/myownpostgresql';

my $sysfh = get_file($sys_fn);

isa_ok($sysfh, 'CAF::FileWriter', "prepare_service creates $sys_fn");
like("$sysfh", qr{PGDATA="/var/lib/pgsql/myversion/data"\nPGLOG="/var/lib/pgsql/myversion/pgstartup.log"\nPGPORT="2345"\n$},
     'prepare_service sysconfig has correct data');

is($sys_changed, 1, 'prepare_service returns changed state of sysconfig file');

done_testing();
