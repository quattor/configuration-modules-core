use strict;
use warnings;

use Test::More;

use NCM::Component::pcs;
use Set::Scalar;

use Readonly;

Readonly my $SIMPLE => <<EOF;
LEVEL one a:
  level two a:
    data two a1: something
LEVEL one b:
  data one b1: a b c
  data one b2:
  data one b3: d e
data zero: 123
EOF

is_deeply(NCM::Component::pcs::_parse($SIMPLE, lower => 1), {
    'level one a' => {
        'level two a' => {
            'data two a1' => 'something',
        },
    },

    'level one b' => {
        'data one b1' => 'a b c',
        'data one b2' => undef,
        'data one b3' => 'd e',
    },
    'data zero' => 123,
}, "simple data parsed ok");
is_deeply(NCM::Component::pcs::_parse($SIMPLE, array => 1), {
    'LEVEL one a' => {
        'level two a' => {
            'data two a1' => ['something'],
        },
    },

    'LEVEL one b' => {
        'data one b1' => [qw(a b c)],
        'data one b2' => [],
        'data one b3' => [qw(d e)],
    },
    'data zero' => [123],
}, "simple data parsed ok as array");


my $sets = NCM::Component::pcs::_parse($SIMPLE, set => 1, lower => 1);
my $origset = Set::Scalar->new('a', 'b', 'c');
my $set = $sets->{'level one b'}->{'data one b1'};
isa_ok($set, 'Set::Scalar', 'value converted to Set::Scalar');
is($set, $origset, "set as expected");

done_testing();
