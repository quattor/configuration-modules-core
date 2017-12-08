use strict;
use warnings;
use Test::More tests => 1;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {foo => 'bar'};

my $rs = $comp->print_ido2db_config($t);
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{ido2db});

is("$fh", "foo=bar\n", "Contents properly written");
