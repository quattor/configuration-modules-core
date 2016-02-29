use strict;
use warnings;
use Test::More tests => 6;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = { foo => { bar => 'baz'} };

my $rs = $comp->print_other($t, "contactgroups");
isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{contactgroups},
   "Correct file was opened");
is("$rs", q!define contactgroup {
	contactgroup_name	foo
	bar	baz
}
!, "Contents properly written");
$rs->close();


$rs = $comp->print_other($t, "servicegroups");

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{servicegroups},
   "Correct file was opened");
is("$rs", q!define servicegroup {
	servicegroup_name	foo
	bar	baz
}
!, "Contents properly written");

$rs->close();
