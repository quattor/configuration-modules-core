#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::sudo;

eval {use Class::Inspector; };

plan skip_all => "Imposible to redefine already tested methods. Skipping" if $@;

my %called;
my $f = Class::Inspector->functions('NCM::Component::sudo');

sub disable_all_executions
{
    my @funcs = @_;
    no strict 'refs';
    no warnings 'redefine';

    my $j;
    foreach my $i (@funcs) {
	*{"NCM::Component::sudo::$i" } = sub {
	    $called{$i} = ++$j;
	    return 0;
	};
    }
    use warnings 'redefine';
    use strict 'refs';
}

my $cmp = NCM::Component::sudo->new('sudo');

my @disabled = grep($_ =~ m{^(?:generate|write)}, @$f);
disable_all_executions(@disabled);
$cmp->Configure();

foreach my $i (grep($_ !~ m{^write}, @disabled)) {
    ok(exists($called{$i}), "Method $i gets called");
    ok($called{$i} < $called{write_sudoers}, "sudoers called after $i");
}

done_testing();
