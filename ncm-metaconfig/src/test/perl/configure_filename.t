#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(filename);
use NCM::Component::metaconfig;
use Test::MockModule;
use CAF::Object;

eval { use JSON::XS; };

plan skip_all => "Testing module not found in the system" if $@;

$CAF::Object::NoAction = 1;

my $mock = Test::MockModule->new('NCM::Component::metaconfig');

=pod

=head1 DESCRIPTION

Test the configure() method with filename specified.

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $cfg = get_config_for_profile('filename');

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file("/foo/bar");
ok($fh, "A file was actually created");
isa_ok($fh, "CAF::FileWriter");

done_testing();
