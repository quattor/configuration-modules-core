#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(no_includes include);
use NCM::Component::sudo;

=pod

=head1 DESCRIPTION

Test the generation of files to be included. Nothing special here.

=cut

my $cmp = NCM::Component::sudo->new('sudo');

my $cfg = get_config_for_profile('include');

my $i = $cmp->generate_includes($cfg, "/software/components/sudo/includes");

is(scalar(@$i), 2, "Includes generated properly");
is($i->[0], "foo", "Include foo properly generated");
is($i->[1], "bar", "Include bar properly generated");

$cfg = get_config_for_profile('no_includes');

$i = $cmp->generate_includes($cfg, "/software/components/sudo/includes");

is(scalar(@$i), 0, "Empty includes generated properly");

done_testing();
