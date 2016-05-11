# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::get_unique_be> method.  This method takes an array
of current boot environments and a preferred name, returning a unique
version of that name if it clashes.

=head1 TESTS

The test provides a dummy list of current boot environment names
and some test BE names, verifying the output.

=cut

use strict;
use warnings;
use Test::More tests => 3;
use Test::Quattor;
use NCM::Component::spma::ips;
use Readonly;
use Set::Scalar;

Readonly my $beadm_list =>
"11.1.10.5.0;3295f569-cb96-6095-fcc5-ea230deead53;;;1152157184;static;1383314046
after-postinstall;86da11ce-a5c0-c9a1-92c3-ffdc850b5824;;;53248;static;1353932413
11.1.12.5.0;4ce21b58-91ce-6748-caf9-f12279aa45ba;;;55820196864;static;1385592777
before-postinstall;40a3490d-12be-418f-9064-cc0a119228fb;;;417792;static;1353929579
test;41b89679-6a23-4aef-f4d6-d88cdf41c17d;;;18536510976;static;1353933808
test-backup-1;2170e922-e65b-678b-cc18-f97e536d4960;;;0;static;1354206957
solaris;92ea8774-d365-4c8e-e0ec-847092cb0869;NR;;1168384;static;1353928512";

my $cmp = NCM::Component::spma::ips->new("spma");

my $bename = $cmp->get_unique_be($beadm_list, "new");
is($bename, "new", "Get unique BE name 'new'");

$bename = $cmp->get_unique_be($beadm_list, "test");
is($bename, "test-1", "Get unique BE name 'test'");

$bename = $cmp->get_unique_be($beadm_list, "test-backup");
is($bename, "test-backup-2", "Get unique BE name 'test-backup'");
