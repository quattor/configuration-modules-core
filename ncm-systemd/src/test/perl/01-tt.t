use strict;
use warnings;

use Test::More;
use Test::Quattor::TextRender::Component;

my $t = Test::Quattor::TextRender::Component->new(
    component => 'systemd',
    version => 'regular',
    )->test();


# insert custom TT options (no easy way to do this via test framework)
use Test::MockModule;
use NCM::Component::Systemd::UnitFile;

my $mock = Test::MockModule->new('CAF::TextRender');
$mock->mock('new', sub {
    my ($self, $module, $contents, %opts) = @_;
    my $init = $mock->original("new");
    $opts{ttoptions} = NCM::Component::Systemd::UnitFile::_make_variables_custom({
        CPUAffinity => [[], [100, 101, 102]],
    });
    my $trd = &$init($self, $module, $contents, %opts);
    return $trd;
});

my $tc = Test::Quattor::TextRender::Component->new(
    component => 'systemd',
    version => 'custom',
    )->test();

done_testing();
