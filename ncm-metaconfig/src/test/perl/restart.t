#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More tests => 3;
use Test::Quattor;
use NCM::Component::metaconfig;
use CAF::Object;


$CAF::Object::NoAction = 1;


=pod

=head1 DESCRIPTION

Test that a daemon gets restarted if needed.

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');

ok($cmp->restart_daemon("foo"), "Successful restart_daemon returns true");
set_command_status("/sbin/service foo restart", 1);
ok(!$cmp->restart_daemon("foo"), "Failed restart_daemon returns false");
is($cmp->{ERROR}, 1, "Failed restart_daemon triggers an error message");
