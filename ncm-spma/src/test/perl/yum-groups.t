# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<expand_groups> method.  This method expands the
contents of a Yum group.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma::yum;
use Test::Quattor;
use CAF::Object;
use Set::Scalar;

$CAF::Object::NoAction = 1;

Readonly my $CMD => join(" ", (NCM::Component::spma::yum::REPOGROUP),
                        "mandatory", "foo");

my $cmp = NCM::Component::spma::yum->new("spma");

set_desired_output($CMD, "a\nb\nc\n");
my $pkgs = $cmp->expand_groups({foo => { optional => '', mandatory => 1}});
isa_ok($pkgs, "Set::Scalar");#, "Group expansion returns a set");
foreach my $pkg (qw(a b c)) {
    ok($pkgs->has($pkg), "Package $pkg in set");
}

$pkgs = $cmp->expand_groups({});
isa_ok($pkgs, "Set::Scalar", "Empty group list returns a set");
ok($pkgs->is_empty(), "Empty group list returns an empty set");

set_command_status($CMD, 1);

$pkgs = $cmp->expand_groups({foo => { optional => '', mandatory => 1 }});
is($pkgs, undef, "Undef is returned upon failure");

done_testing();
