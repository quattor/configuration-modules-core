# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Basic tests for NCM::Component::spma::dnf module.

=cut

use strict;
use warnings;
use Test::More;
use NCM::Component::spma::dnf;
use CAF::Object;
use Test::Quattor::Object;
use Readonly;

$CAF::Object::NoAction = 1;

my $obj = Test::Quattor::Object->new;

=pod

=head2 Test component instantiation

=cut

my $cmp = NCM::Component::spma::dnf->new("spma", $obj);
isa_ok($cmp, "NCM::Component::spma::dnf", "Component instantiated correctly");
isa_ok($cmp, "NCM::Component", "Inherits from NCM::Component");

=pod

=head2 Test constants are defined

=cut

is(NCM::Component::spma::dnf::REPOS_DIR, "/etc/yum.repos.d", "REPOS_DIR constant correct");
is(NCM::Component::spma::dnf::DNF_MODULES_DIR, "/etc/dnf/modules.defaults.d", "DNF_MODULES_DIR constant correct");
is(NCM::Component::spma::dnf::DNF_CONF_FILE, "/etc/dnf/dnf.conf", "DNF_CONF_FILE constant correct");
is(NCM::Component::spma::dnf::DNF_PACKAGE_LIST, "/etc/dnf/plugins/versionlock.list", "DNF_PACKAGE_LIST constant correct");
is(NCM::Component::spma::dnf::PROTECT_FILE, "/etc/dnf/protected.d/dnf.conf", "PROTECT_FILE constant correct");

=pod

=head2 Test NoActionSupported flag

=cut

ok($NCM::Component::spma::dnf::NoActionSupported, "NoActionSupported is true");

done_testing();
