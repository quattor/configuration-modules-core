# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Basic yumdnf tests.

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor qw(yumdnf_simple);
use NCM::Component::spma::yumdnf;
use CAF::Object;
use Test::Quattor::Object;
use Test::MockModule;
use NCM::Component::spma;

$CAF::Object::NoAction = 1;

my $obj = Test::Quattor::Object->new;

=pod

=item Test basic subclassing constants

=cut

my $cmp = NCM::Component::spma::yumdnf->new("spma", $obj);

# Test _set_yum_config
# Only the default config is active
is_deeply($cmp->_set_yum_config([qw(a b c)]),
         ['a', '-c', '/etc/dnf/dnf.conf', 'b', 'c'], "Inserted (default) yum/dnf config");


=item Test general loading of packager

=cut

my $mock = Test::MockModule->new('NCM::Component::spma::yumdnf');
$mock->mock('Configure', 'ConfigureYumdnf');

my $cfg = get_config_for_profile("yumdnf_simple");

my $cmpfull = NCM::Component::spma->new("spma");

is($cmpfull->Configure($cfg), 'ConfigureYumdnf', 'yumdnf loaded via SPMA_BACKEND');

done_testing();


=pod

=back

=cut
