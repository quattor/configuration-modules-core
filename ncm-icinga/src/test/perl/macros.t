use strict;
use warnings;
use Test::More tests => 1;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {foo => 'bar'};

my $rs = $comp->print_macros($t);

my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{macros});

is("$fh", '$foo$=bar'."\n", 'File contents properly written');
