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

=head2 Test NoActionSupported flag

=cut

done_testing();
