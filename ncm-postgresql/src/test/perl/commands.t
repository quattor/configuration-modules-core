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

my $expected_fn = '/';
$mock->mock('_file_exists', sub {
    my ($self, $filename) = @_;
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


done_testing();
