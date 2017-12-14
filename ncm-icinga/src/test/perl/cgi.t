use strict;
use warnings;
use Test::More tests => 3;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {
	 hello => 1,
	 world => 2
	};

my $rs = $comp->print_cgi($t);

my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{cgi});

like($fh, qr(^main_config_file=.*),
     "The main config file is printed");
like($fh, qr{^hello=1$}m, "Key hello got printed");
like($fh, qr{^world=2$}m, "Key world got printed");
