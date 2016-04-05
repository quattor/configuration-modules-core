# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;
use Readonly;
use English;

use Test::Quattor;
use Test::More;
use Test::Deep;
use Set::Scalar;
use NCM::Component::spma::apt;

my $set = Set::Scalar->new(
    "example-package",
    "another-package-name",
);

my $tree = {
    "example_2dpackage" => {
        "_31_2e5_2e0_2d1" => {
            "arch" => {
                "i686" => "",
                "amd64" => "",
            }
        },
        "_31_2e7_2e1_2d1" => {
            "arch" => {
                "amd64" => "",
            }
        },
        "_31_2e9_2e0_2d1" => undef,
    },
    "another_2dpackage_2dname" => undef,
};

my $desired_details = [
    "example-package:i686=1.5.0-1",
    "example-package:amd64=1.5.0-1",
    "example-package:amd64=1.7.1-1",
    "example-package=1.9.0-1",
    "another-package-name",
];

my $cmp = NCM::Component::spma::apt->new("spma");

# Ordering of the sets doesn't matter here, so use cmp_bag from Test::Deep to compare
cmp_bag($cmp->apply_package_version_arch($set, $tree), $desired_details, "Package details translated");

done_testing();
