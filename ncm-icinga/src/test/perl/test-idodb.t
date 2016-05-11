use strict;
use warnings;
use Test::More tests => 3;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {foo => 'bar'};

my $rs = $comp->print_ido2db_config($t);
isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{ido2db}, "Correct file was opened");
is("$rs", "foo=bar\n", "Contents properly written");

$rs->close();
