use strict;
use warnings;
use Test::More tests => 3;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {foo => 'bar'};

my $rs = $comp->print_macros($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{macros}, "Correct file was opened");
chomp($rs);
is($rs, '$foo$=bar', 'File contents properly written');
