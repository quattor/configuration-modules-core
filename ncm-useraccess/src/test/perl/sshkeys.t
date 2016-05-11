#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::Quattor;
use Test::More;
use Cwd;
use NCM::Component::useraccess;
use CAF::Object;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<set_ssh_fromkeys> method.

=head1 TESTS

=head2 An key from an accessible URL is retrieved

This is the basic, usual case.

=cut

my $cmp = NCM::Component::useraccess->new("useraccess");

my $u = { ssh_keys => [qw(key1 key2)] };

my $fh = CAF::FileWriter->new("target/test/ssh_keys_test_1");

is($cmp->set_ssh_fromkeys("foo", $u, $fh), 0,
   "SSH from keys returns with no errors");
is("$fh", "key1\nkey2\n", "The SSH file has the correct contents");

# cleanup fh
$fh->close();

=pod

=head2 An empty URL list is handled correctly

The method is successful, but the file is empty.

=cut

$u->{ssh_keys} = [];

$fh = CAF::FileWriter->new("target/test/ssh_keys_test_2");

is($cmp->set_ssh_fromurls("foo", $u, $fh), 0,
   "SSH with empty key list returns with no errors");
is("$fh", "", "The SSH file is empty when the key list is empty");

=pod

=head2 The method handles naturally non-existing key lists

This shouldn't raise any errors.

=cut

is($cmp->set_ssh_fromurls("foo", {}, $fh), 0,
   "SSH with no key list returns with no errors");
is("$fh", "", "The SSH file is empty when there is no URL list");
ok(!$cmp->{ERROR}, "No errors when populated authorized_hosts so far");

# cleanup fh
$fh->close();

=pod

=head2 The method raises an error if the file is wrong

I don't remember how this could happen, but it's better to test it
now.

=cut

$u->{ssh_keys} = [qw(foo bar)];

is($cmp->set_ssh_fromkeys("foo", $u), -1,
   "Invalid filehandle gets reported");
is($cmp->{ERROR}, 1, "The filehandle error is reported");

=pod

=head2 The absence of the keys list doesn't trigger any errors

=cut

is($cmp->set_ssh_fromkeys("foo", {}), 0,
   "Non-existing SSH keys list is handled correctly");

done_testing();


