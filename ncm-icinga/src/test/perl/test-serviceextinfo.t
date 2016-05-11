use strict;
use warnings;
use Test::More tests => 5;

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

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(
    *$rs->{filename},
    NCM::Component::icinga::ICINGA_FILES->{serviceextinfo},
    "Correct file was opened"
);
like("$rs", qr(^\s*foo\s+1$)m,   "Scalar contents properly written");
like("$rs", qr(^\s*bar\s+3,4$)m, "List contents properly written");

$rs->close();
