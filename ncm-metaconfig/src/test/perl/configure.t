#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simple);
use NCM::Component::metaconfig;
use CAF::Object;

eval { use JSON::XS; };

plan skip_all => "Testing module not found in the system" if $@;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the configure() method.

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $cfg = get_config_for_profile('simple');

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file("/foo/bar");
ok($fh, "A file was actually created");
isa_ok($fh, "CAF::FileWriter");

my $c = get_command("/sbin/service foo restart");
ok(!$c, "Daemon was not restarted when there are no changes");

# Pretend there are changes

no warnings 'redefine';
*NCM::Component::metaconfig::needs_restarting = sub {
    return 1;
};
use warnings 'redefine';

$cmp->Configure($cfg);
$c = get_command("/sbin/service foo restart");
ok($c, "Daemon was restarted when there were changes");

done_testing();
