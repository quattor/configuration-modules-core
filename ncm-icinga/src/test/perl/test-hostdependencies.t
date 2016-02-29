use strict;
use warnings;
use Test::More tests => 6;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {
    ahost => {
        foo => 1,
        bar => [3, 4],
    }
};

my $rs = $comp->print_hostdependencies();

ok(!defined($rs), "Nothing is done if there are no host dependencies");

$rs = $comp->print_hostdependencies($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(
    *$rs->{filename},
    NCM::Component::icinga::ICINGA_FILES->{hostdependencies},
    "Correct file was opened"
);
like("$rs", qr(^\s*foo\s+1$)m,           "Scalar contents properly written");
like("$rs", qr(^\s*bar\s+3,4$)m,         "List contents properly written");
like("$rs", qr(^\s*host_name\s+ahost$)m, "Host name properly recorded");

$rs->close();
