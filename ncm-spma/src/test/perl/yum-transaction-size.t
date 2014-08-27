# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the sizes of the transactions and queries.

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use Test::MockModule;
use Set::Scalar;

my $cmp = NCM::Component::spma::yum->new("spma");
my $mock = Test::MockModule->new("NCM::Component::spma::yum");

foreach my $method (qw(complete_transaction expire_yum_caches versionlock
		       distrosync apply_transaction)) {
    $mock->mock($method, 1);
}

$mock->mock("wanted_pkgs", Set::Scalar->new(qw(incomplete complete;noarch
					       reallywanted)));
$mock->mock("installed_pkgs", Set::Scalar->new(qw(incomplete complete;noarch
						  incomplete;i386)));
$mock->mock("expand_groups", Set::Scalar->new(qw(extra)));

$mock->mock("schedule", sub {
		my ($self, $op, $install) = @_;
		is(scalar(@$install), 2, "Only two packages are left for install");
		ok($install->has("reallywanted"),
		   "Correct package will be installed");
                ok($install->has("extra"), "Package from group will be installed");
		return "";
	    });

$cmp->update_pkgs({}, {}, 0, 1);


done_testing();
