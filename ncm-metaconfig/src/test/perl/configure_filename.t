#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::metaconfig;

use Test::MockModule;
use CAF::Object;

eval { use JSON::XS; };

plan skip_all => "Testing module not found in the system" if $@;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the configure() method with filename specified.

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');

my $cfg = {
       owner => 'root',
       group => 'root',
       mode => 0644,
       filename => '/foo/bar',
       contents => {
            foo => 'bar',
            },
       module => "json",
      };

ok($cmp->handle_service("filenametest", $cfg), "Config rendered.");
my $fh = get_file("/foo/bar");
ok($fh, "A file was actually created with correct filename");
isa_ok($fh, "CAF::FileWriter");


done_testing();
