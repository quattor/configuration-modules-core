use strict;
use warnings;
use Test::More tests => 3;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = [
    {
        foo => 1,
        bar => [3, 4],
    }
];

my $rs = $comp->print_serviceextinfo();

ok(!defined($rs), "Nothing is done if there is no service extinfo");

$rs = $comp->print_serviceextinfo($t);

my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{serviceextinfo});

like($fh, qr(^\s*foo\s+1$)m,   "Scalar contents properly written");
like($fh, qr(^\s*bar\s+3,4$)m, "List contents properly written");
