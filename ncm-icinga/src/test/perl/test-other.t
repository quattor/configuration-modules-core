use strict;
use warnings;
use Test::More tests => 2;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = { foo => { bar => 'baz'} };

my $rs = $comp->print_other($t, "contactgroups");
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{contactgroups});

is("$fh", q!define contactgroup {
	contactgroup_name	foo
	bar	baz
}
!, "Contents properly written");

$rs = $comp->print_other($t, "servicegroups");
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{servicegroups});
is("$fh", q!define servicegroup {
	servicegroup_name	foo
	bar	baz
}
!, "Contents properly written");
