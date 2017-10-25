use strict;
use warnings;
use Test::More;
use EDG::WP4::CCM::Path qw(escape);
use Test::Quattor qw(unitfile_config);
use NCM::Component::systemd;
use NCM::Component::Systemd::UnitFile;
use Test::MockModule;
use Test::Quattor::Object;
use Test::Quattor::TextRender::Base;

my $mocked_trd = mock_textrender();

my $conf = get_config_for_profile('unitfile_config');

my $mockuf = Test::MockModule->new('NCM::Component::Systemd::UnitFile');

=pod

=head1 DESCRIPTION

Test unitfile configuration generation

=head2 _initialize

=cut

my $unitr = 'regular.service';
my $basepath = '/software/components/systemd/unit';
my $elr = $conf->getElement("$basepath/".escape($unitr)."/file/config");

my $ur = NCM::Component::Systemd::UnitFile->new($unitr, $elr, backup => '.veryold');
isa_ok($ur, 'NCM::Component::Systemd::UnitFile', 'ur is a NCM::Component::Systemd::UnitFile instance');
isa_ok($ur, 'CAF::Object', 'ur is a CAF::Object subclass');
is($ur->{unit}, $unitr, 'ur unit attribute set');
is($ur->{config}, $elr, 'ur config is the passed Element instance');
is($ur->{replace}, 0, 'ur replace=0 set');
is($ur->{backup}, '.veryold', 'backup set');
ok(! defined($ur->{custom}), "custom attribute not defined");


my $unitf = 'replace.service';
my $elf = $conf->getElement("$basepath/".escape($unitf)."/file/config");

my $uf = NCM::Component::Systemd::UnitFile->new($unitf, $elf, replace => 1, custom => {CPUAffinity => ['node:0', 'node:2']});
isa_ok($uf, 'NCM::Component::Systemd::UnitFile', 'uf is a NCM::Component::Systemd::UnitFile instance');
isa_ok($uf, 'CAF::Object', 'uf is a CAF::Object subclass');
is($uf->{unit}, $unitf, 'uf unit attribute set');
is($uf->{config}, $elf, 'uf config is the passed Element instance');
is($uf->{replace}, 1, 'uf replace=1 set');
ok(! defined($uf->{backup}), 'no backup set');
is_deeply($uf->{custom}, {CPUAffinity => ['node:0', 'node:2']}, "custom attribute set");

=head2 custom

=over

=item CUSTOM_ATTRIBUTES

=cut

my @customs = sort keys %NCM::Component::Systemd::UnitFile::CUSTOM_ATTRIBUTES;
is_deeply(\@customs, ['CPUAffinity'],
          'list of supported custom attributes');

foreach my $attr (@customs) {
    my $cmethod = $NCM::Component::Systemd::UnitFile::CUSTOM_ATTRIBUTES{$attr};
    ok($ur->can($cmethod),
       "UnitFile instance has cutom method $cmethod for attribute $attr");
}

=item CPUAffinity / _hwloc_calc_cpus / _hwloc_calc_cpus

=cut

set_desired_output('hwloc-calc --physical-output --intersect PU node:0 node:2', '0,1,2,12,13,14,6,7,8,18,19,20');
is_deeply($ur->_hwloc_calc_cpus(['node:0', 'node:2']), [0,1,2,12,13,14,6,7,8,18,19,20],
          '_hwloc_calc_cpus handles output from numanode 0 and 2');
is_deeply($ur->_hwloc_calc_cpuaffinity(['node:0', 'node:2']), [[],[0,1,2,12,13,14,6,7,8,18,19,20]],
          '_hwloc_calc_cpuaffinty handles output from numanode 0 and 2 and returns list of list with first element empty');

# unexpected/fake output (should not output ranges)
set_desired_output('hwloc-calc --physical-output --intersect PU node:10', '0,1,2,12-14');
ok(! defined($ur->_hwloc_calc_cpus(['node:10'])),
   '_hwloc_calc_cpus with unexpected output results in undef');
ok(! defined($ur->_hwloc_calc_cpuaffinity(['node:10'])),
   '_hwloc_calc_cpuaffinity with unexpected output results in undef');

=item _make_variables_custom

=cut

is_deeply(NCM::Component::Systemd::UnitFile::_make_variables_custom({random => 'data'}),
          {VARIABLES => {SYSTEMD => {CUSTOM => { random => 'data'}}}},
          '_make_variables_custom generated the required ttoptions hashref structure');

=item custom

=cut

is_deeply($ur->custom(), {},
          "custom method returns empty hashref (no undef) for empty/missing custom attribute");

# insert non-supported custom attribute
$uf->{custom}->{unsupported} = 'x';
ok(! defined($uf->custom()), "custom method returns undef with non-supported attribute");
delete $uf->{custom}->{unsupported};

my $customdata = {CPUAffinity => [[],[0,1,2,12,13,14,6,7,8,18,19,20]]};
is_deeply($uf->custom(), $customdata,
          "custom method returns hashref with CPUAffinity");

=item prepare_path

=cut

my $testunitfilesdir = "target/test/unitfiles";
reset_caf_path();
is($ur->_prepare_path($testunitfilesdir), "$testunitfilesdir/regular.service.d/quattor.conf",
   "_prepare_path returned non-replace filename on succesful cleanup (replace=0)");
is_deeply($Test::Quattor::caf_path, {
    'cleanup' => [[["$testunitfilesdir/regular.service", undef], {}]],
    'directory' => [[["$testunitfilesdir/regular.service.d"], {}]]
}, "_prepare_path called cleanup with dest unit file (replace=0) and creates directory for non-replace files");

reset_caf_path();
is($uf->_prepare_path($testunitfilesdir), "$testunitfilesdir/replace.service",
   "_prepare_path returned unitfile filename on succesful cleanup (replace=1)");
is_deeply($Test::Quattor::caf_path, {
    'cleanup' => [[["$testunitfilesdir/replace.service.d", undef], {}]],
}, "_prepare_path called cleanup with dest unitfile dir (replace=1)");

=item write

=cut

my @args;
$mockuf->mock('custom', sub { return;} );
ok(! defined($ur->write()), "write returns undef on failing custom");

$mockuf->mock('custom', sub { return $customdata;} );
$mockuf->mock('_prepare_path', sub {shift; push(@args, shift); return;} );

@args=();
ok(! defined($ur->write()), "write returns undef on failing _prepare_path");
is_deeply(\@args, ['/etc/systemd/system'], "_prepare_path called with system unit dir");

# doesn't really mattter how it is mocked
my $unitfilename = "$testunitfilesdir/woohoo.service";
$mockuf->mock('_prepare_path', sub {return $unitfilename;} );
ok($ur->write(), "write returns changed status (and it's new, so changed)");

ok(get_command('/usr/bin/systemctl daemon-reload'), 'daemon-reload called upon change');

my $fh = get_file($unitfilename);
isa_ok($fh, 'CAF::FileWriter', 'write sets a FileWriter instance');
is(*$fh->{options}->{mode}, 0664, "correct mode set to FileWriter");
is(*$fh->{options}->{backup}, '.veryold', 'backup settings passed');

diag "$fh";
like("$fh", qr{CPUAffinity=0 1 2 12 13 14 6 7 8 18 19 20}m, "Custom CPUAffinity set");

like("$fh", qr{^After=g-h-i.mount$}m, "systemd_make_mountunit function ok");

# test non-config element
my $orig_config = $ur->{config};
$ur->{config} = {a => 1};
ok(! defined($ur->write()), "write returns undef on non-Element instance");

done_testing();
