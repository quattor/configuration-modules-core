# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<versionlock> method.  This method adds all packages
from the profile to a file in /etc.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma;
use Test::Quattor;
use CAF::Object;
use Set::Scalar;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma->new("spma");
my $pkg = Set::Scalar->new(qw(a b));

$cmp->versionlock($pkg);

my $fh = get_file("/etc/yum/pluginconf.d/versionlock.list");

like($fh, qr{a\n}, "Package a listed in version lock");
like($fh, qr{b\n}, "Package b listed in version lock");

done_testing();
