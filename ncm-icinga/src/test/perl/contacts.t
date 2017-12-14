use strict;
use warnings;
use Test::More tests => 4;

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
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{contacts});

like($fh, qr(^\s*alias\s+foo$)m, "Alias properly written");
like(
    $fh,
    qr(^\s*host_notification_commands\s+1!2,3!4$)m,
    "Notification commands properly written"
);
like($fh, qr(^\s*foo\s+4,5$)m, "Random array field properly written");
like($fh, qr(^\s*bar\s+6$)m,   "Random scalar field properly written");
