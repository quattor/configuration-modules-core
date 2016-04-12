use strict;
use warnings;
use Test::More tests => 6;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {
    acontact => {
        alias                      => 'foo',
        host_notification_commands => [[1, 2], [3, 4]],
        foo => [4, 5],
        bar => 6
    }
};

my $rs = $comp->print_contacts($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");

is(
    *$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{contacts},
    "Correct file was opened"
);

like("$rs", qr(^\s*alias\s+foo$)m, "Alias properly written");
like(
    "$rs",
    qr(^\s*host_notification_commands\s+1!2,3!4$)m,
    "Notification commands properly written"
);
like("$rs", qr(^\s*foo\s+4,5$)m, "Random array field properly written");
like("$rs", qr(^\s*bar\s+6$)m,   "Random scalar field properly written");

$rs->close();
