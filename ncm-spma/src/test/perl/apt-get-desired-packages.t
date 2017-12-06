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
use Set::Scalar;
use NCM::Component::spma::apt;
use Data::Dumper;


my $packages = {
    "nss_2dsoftokn_2dfreebl" => {},
    "initscripts" => {},
    "cyrus_2dsasl_2dlib" => {},
    "b43_2dopenfwwf" => {},
};

my $desired_packages = Set::Scalar->new(
    "b43-openfwwf",
    "cyrus-sasl-lib",
    "initscripts",
    "nss-softokn-freebl",
);

my $cmp = NCM::Component::spma::apt->new("spma");

is($cmp->get_desired_pkgs($packages), $desired_packages, "Get list of desired packages");

done_testing();
