use strict;
use warnings;
use Test::More tests => 17;
use Test::Quattor;
use NCM::Component::iptables;

my $cmp = NCM::Component::iptables->new('iptables');

is($cmp->uppercase('abc'), 'ABC', 'uppercase capitalises correctly');
is($cmp->uppercase('123'), '123', 'uppercase ignores numerals');

is($cmp->trim_whitespace(), '', 'trim_whitespace returns empty string when undef passed');
is($cmp->trim_whitespace('     Hemispheres'), 'Hemispheres', 'trim_whitespace removes leading whitespace');
is($cmp->trim_whitespace('Permanent Waves        '), 'Permanent Waves', 'trim_whitespace removes trailing whitespace');
is($cmp->trim_whitespace('  Moving Pictures   '), 'Moving Pictures', 'trim_whitespace remove leading and trailing whitespace');

is($cmp->collapse_whitespace(), '', 'collapse_whitespace returns empty string when undef passed');
is($cmp->collapse_whitespace('Signals      '), 'Signals ', 'collapse_whitespace collapses leading whitespace');
is($cmp->collapse_whitespace('Grace          Under    Pressure'), 'Grace Under Pressure', 'collapse_whitespace collapses inner whitespace');
is($cmp->collapse_whitespace('        Power Windows'), ' Power Windows', 'collapse_whitespace collapses leading whitespace');
is($cmp->collapse_whitespace("Hold\tYour\tFire"), 'Hold Your Fire', 'collapse_whitespace collapses tabs');

is($cmp->quote_string('word'), 'word', 'quote_string does not quote a single word');
is($cmp->quote_string('  whitespace    '), 'whitespace', 'quote_string does not quote a single word surrounded by whitespace');
is($cmp->quote_string('multiple words'), '"multiple words"', 'quote_string quotes multiple words correctly');
is($cmp->quote_string('   multiple  whitespaced  words   '), '"multiple  whitespaced  words"', 'quote_string quotes multiple words surrounded by whitespace correctly');

# Test sort_keys method
my $example_rule = {
    '--comment' => 'Should be last',
    '-j' => 'Should be middle',
    '-A' => 'Should be first',
};

my @sorted = $cmp->sort_keys($example_rule);
my @expected = ('-A', '-j', '--comment');

is_deeply(\@sorted, \@expected, "sort_keys sorts example keys correctly");
undef $example_rule, @sorted, @expected;

# Test rule_options_translate method
my $translate_rule = {
    'append' => 'abc',
    'source' => 'def',
    'jump' => 'ghi',
};
my $translate_expected = {
    '-A' => 'abc',
    '-s' => 'def',
    '-j' => 'ghi',
};
$cmp->rule_options_translate($translate_rule);

is_deeply($translate_rule, $translate_expected, 'rule_options_translate translates example correctly');

done_testing();
