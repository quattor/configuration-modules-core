use strict;
use warnings;
use Test::More tests => 6;
use NCM::Component::iptables;

is(NCM::Component::iptables->uppercase('abc'), 'ABC', 'function uppercase capitalises correctly');
is(NCM::Component::iptables->uppercase('123'), '123', 'function uppercase ignores numerals');

is(NCM::Component::iptables->quote_string('word'), 'word', 'function quote_string does not quote a single word');
is(NCM::Component::iptables->quote_string('  whitespace    '), 'whitespace', 'function quote_string does not quote a single word surrounded by whitespace');
is(NCM::Component::iptables->quote_string('multiple words'), '"multiple words"', 'function quote_string quotes multiple words correctly');
is(NCM::Component::iptables->quote_string('   multiple  whitespaced  words   '), '"multiple  whitespaced  words"', 'function quote_string quotes multiple words surrounded by whitespace correctly');

done_testing();
