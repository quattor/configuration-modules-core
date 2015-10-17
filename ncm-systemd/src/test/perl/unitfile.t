use strict;
use warnings;
use Test::More;
use EDG::WP4::CCM::Element qw(escape);
use Test::Quattor qw(unitfile_config);
use NCM::Component::systemd;
use NCM::Component::Systemd::UnitFile;

$CAF::Object::NoAction = 1;

my $conf = get_config_for_profile('unitfile_config');

=pod

=head1 DESCRIPTION

Test unitfile configuration generation

=head2 _initialize

=cut

my $unitr = 'regular.service';
my $basepath = '/software/components/systemd/unit';
my $elr = $conf->getElement("$basepath/".escape($unitr)."/file/config");

my $ur = NCM::Component::Systemd::UnitFile->new($unitr, $elr);
isa_ok($ur, 'NCM::Component::Systemd::UnitFile', 'ur is a NCM::Component::Systemd::UnitFile instance');
isa_ok($ur, 'CAF::Object', 'ur is a CAF::Object subclass');
is($ur->{unit}, $unitr, 'ur unit attribute set');
is($ur->{config}, $elr, 'ur config is the passed Element instance');
is($ur->{force}, 0, 'ur force=0 set');


my $unitf = 'force.service';
my $elf = $conf->getElement("$basepath/".escape($unitf)."/file/config");

my $uf = NCM::Component::Systemd::UnitFile->new($unitf, $elf, force => 1);
isa_ok($uf, 'NCM::Component::Systemd::UnitFile', 'uf is a NCM::Component::Systemd::UnitFile instance');
isa_ok($uf, 'CAF::Object', 'uf is a CAF::Object subclass');
is($uf->{unit}, $unitf, 'uf unit attribute set');
is($uf->{config}, $elf, 'uf config is the passed Element instance');
is($uf->{force}, 1, 'uf force=1 set');



done_testing();
