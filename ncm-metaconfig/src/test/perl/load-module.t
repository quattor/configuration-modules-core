#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::metaconfig;

my $mod;

foreach my $i (qw(JSON::XS YAML::XS Config::General)) {
    eval "use $i";
    if (!$@) {
	$mod = $i;
	last;
    }
}

if ($@) {
    plan skip_all => "No known configuration-rendering module found";
}


=pod

=head1 DESCRIPTION

Test how configuration-rendering modules are loaded.

=cut

my $cmp = NCM::Component::metaconfig->new('metaconfig');



=pod

=head1 TESTS

=head2 Load a valid module

=cut

ok($cmp->load_module($mod), "Load module $mod works");

=pod

=head2 Load an invalid module

=cut

ok(!$cmp->load_module('foobarbaz'), "Invalid module loading fails");
ok($@, "Invalid module loading raises an exception");
is($cmp->{ERROR}, 1, "Error was reported");

done_testing();
