#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More tests => 3;
use Test::Quattor qw(simple);
use NCM::Component::metaconfig;
use CAF::Object;
use CAF::FileWriter;

$CAF::Object::NoAction = 1;

my $pretend_changed;

no warnings 'redefine';
*CAF::FileWriter::close = sub {
    return $pretend_changed;
};
use warnings 'redefine';

=pod

=head1 DESCRIPTION

Test how the need for restarting a service is handled

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $fh = CAF::FileWriter->new('foo');
ok(!$cmp->needs_restarting($fh, { 'daemon' => 'foo' }),
   "No restarting on unchanged file");
$pretend_changed = 1;
ok(!$cmp->needs_restarting($fh, {}), "No restarting if no daemon");
ok($cmp->needs_restarting($fh, { 'daemon' => 'foo' }),
   "Restart only if the file changes and there is a daemon associated");

