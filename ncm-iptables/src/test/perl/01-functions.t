use strict;
use warnings;
use Test::More tests => 6;
use NCM::Component::iptables;

my $cmp = NCM::Component::iptables->new('iptables');

is($cmp->uppercase('abc'), 'ABC', 'function uppercase capitalises correctly');
is($cmp->uppercase('123'), '123', 'function uppercase ignores numerals');

is($cmp->quote_string('word'), 'word', 'function quote_string does not quote a single word');
is($cmp->quote_string('  whitespace    '), 'whitespace', 'function quote_string does not quote a single word surrounded by whitespace');
is($cmp->quote_string('multiple words'), '"multiple words"', 'function quote_string quotes multiple words correctly');
is($cmp->quote_string('   multiple  whitespaced  words   '), '"multiple  whitespaced  words"', 'function quote_string quotes multiple words surrounded by whitespace correctly');

done_testing();
