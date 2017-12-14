use strict;
use warnings;
use Test::More tests => 4;

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

my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{hostdependencies});

like($fh, qr(^\s*foo\s+1$)m,           "Scalar contents properly written");
like($fh, qr(^\s*bar\s+3,4$)m,         "List contents properly written");
like($fh, qr(^\s*host_name\s+ahost$)m, "Host name properly recorded");
