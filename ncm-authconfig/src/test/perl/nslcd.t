# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<configure_nslcd> method.  We only ensure the file has a
valid format.

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::authconfig;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::authconfig->new("authconfig");

my $t = {
    enable => 1,
    basedn => "abasedn",
    map => {
        foo => { bar => 2 },
        baz => { quux => 3 }
       },
    uri => [5..7],
    blah => 9,
    bleh => [10..15],
};

my $t2 = $t;

$cmp->configure_nslcd($t);

my $fh = get_file("/etc/nslcd.conf");

while (my ($k, $v) = each(%$t2)) {
    like($fh, qr{^$k\s}m, "Field $k starts its own line");
}

done_testing();
