#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More tests => 4;
use Test::Quattor;
use NCM::Component::metaconfig;
use CAF::Object;


$CAF::Object::NoAction = 1;


=pod

=head1 DESCRIPTION

Test that a daemon gets restarted if needed, the Solaris way

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');

ok($cmp->restart_solaris("foo"), "Successful restart_daemon returns true");
ok(get_command("svcadm restart foo"), "The expected command was run");
set_command_status("svcadm restart foo", 1);
ok(!$cmp->restart_solaris("foo"), "Failed restart_daemon returns false");
is($cmp->{ERROR}, 1, "Failed restart_daemon triggers an error message");
