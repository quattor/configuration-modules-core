use strict;
use warnings;
use Test::More tests => 5;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {
	 hello => 1,
	 world => 2
	};

my $rs = $comp->print_cgi($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");

is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{cgi},
    "Correct file was opened");

like("$rs", qr(^main_config_file=.*),
     "The main config file is printed");
like("$rs", qr{^hello=1$}m, "Key hello got printed");
like("$rs", qr{^world=2$}m, "Key world got printed");

$rs->close();
