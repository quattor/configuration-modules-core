#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::MockModule;
use subs qw(LC::File::file_contents LC::Check::file LC::File::move);
use Test::Quattor qw(basic);
use NCM::Component::shorewall;

use CAF::Object;

$CAF::Object::NoAction = 1;


my $check = Test::MockModule->new("LC::Check");

$check->mock('file', 1);

my $file = Test::MockModule->new("LC::File");

$file->mock("move", 1);
$file->mock("file_contents", "some_contents");

=pod


=head1 DESCRIPTION

Tests for the C<configure> method of C<NCM::Component::shorewall>

Basic test to help the refactoring of the component.

=cut

my $cmp = NCM::Component::shorewall->new('shorewall');


my $cfg = get_config_for_profile('basic');

$cmp->Configure($cfg);
ok(!exists($cmp->{ERROR}), "Configure succeeds");


done_testing();
