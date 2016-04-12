# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::merge_pkg_paths> and C<ips::gethash_ips> methods.  These
methods merge package lists from multiple resource paths and convert them
from nlists into a hash of package names and version numbers.

=head1 TESTS

The test provides some representative resource paths to the methods and
verifies the output.

=cut

use strict;
use warnings;
use Test::More tests => 8;
use Test::Quattor qw(ips-core);
use NCM::Component::spma::ips;

use constant CMP_TREE => "/software/components/spma";

sub test_pkgs
{
    my ($pkg_hash, $pkg_type) = @_;
    my $prefix_ok = 1;
    my $ver_ok = 1;

    while (my ($pkg, $ver) = each %$pkg_hash) {
        $prefix_ok = 0 if $pkg !~ "^pkg:";
        $ver_ok = 0 if $ver ne '' and $ver !~ /^[0-9TZ.,:-]*$/;
    }

    ok($prefix_ok, "$pkg_type packages have pkg:/ prefix");
    ok($ver_ok, "$pkg_type package versions match correct format");
}

my $cmp = NCM::Component::spma::ips->new("spma");
my $config = get_config_for_profile("ips-core");
my $t = $config->getElement(CMP_TREE)->getTree();

my $merged_pkgs = $cmp->merge_pkg_paths($config, $t->{pkgpaths});
my $merged_uninst = $cmp->merge_pkg_paths($config, $t->{uninstpaths});

is(keys(%$merged_pkgs), 4, "Merge of resources referenced by pkgpaths");
is(keys(%$merged_uninst), 14, "Merge of resources referenced by uninstpaths");

my $wanted = $cmp->gethash_ips($merged_pkgs);
my $reject = $cmp->gethash_ips($merged_uninst);

is(keys(%$wanted), 4, "Wanted packages generated from nlist resource");
is(keys(%$reject), 14, "Rejected packages generated from nlist resource");

test_pkgs($wanted, "Wanted");
test_pkgs($reject, "Reject");
