#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::Quattor;
use Test::More tests => 4;
use NCM::Component::useraccess;

=pod

=head1 DESCRIPTION

Test the C<getpwnam> stub, which only returns the UID, GID and home
for any given user, failing if the user doesn't exist.

=cut

my $cmp = NCM::Component::useraccess->new('useraccess');

my @r = $cmp->getpwnam("root");
is($r[0], 0, "Correct UID for root account");
is($r[1], 0, "Correct GID for root account");
is($r[2], "/root", "Correct home dir specified");
is($cmp->getpwnam("luhlujhlijhjklh"), undef,
   "Non-existing user is identified and reported");
