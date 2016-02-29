# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

More tests for the C<installed_pkgs> method. This time we test that
all the RPMs are printed in a format that YUM will understand.

=head1 TESTS

These tests will run only if the RPM binary is present.  They consist
on retrieving the set of all installed packages and ensure there are
no surprising strings among them.

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;


plan skip_all => "No RPM database to play with" if ! -x "/bin/rpm";

my $cmp = NCM::Component::spma::yum->new("spma");

my $pkgs = $cmp->installed_pkgs();
isa_ok($pkgs, "Set::Scalar", "Received an empty set, with no errors");

# Watch out: GPG keys for a repository may be shipped via RPMs, and
# those may have a "(none)" arch.
foreach my $pkg (@$pkgs) {
    like($pkg, qr{^(?:[-+\.\w]+)(?:;\w+)?$},
	 "Package $pkg has the correct format string");
    like($pkg, qr{^([\w\.\-\+]+)[*?]?},
	 "Package $pkg matches our wildcard regexp");
}

done_testing();
