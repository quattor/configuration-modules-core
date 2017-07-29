#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::Quattor;
use Test::More;
use Cwd;
use File::Path qw(rmtree mkpath);
use NCM::Component::useraccess;
use Readonly;
use CAF::Object;

$CAF::Object::NoAction = 1;

Readonly my $HOME => "/home/dir";

sub set_user
{
    my $cur = getcwd();
    my $dir = "$cur/target/test/ssh";
    mkpath($dir);
    open(my $fh, ">", "$dir/a.key");
    print $fh "foo bar\n";
    return "file://$dir/a.key";
}

=pod

=head1 DESCRIPTION

Test the C<set_ssh_fromurls> method.

=head1 TESTS

=head2 An key from an accessible URL is retrieved

This is the basic, usual case.

=cut

my $cmp = NCM::Component::useraccess->new("useraccess");

my $u = { ssh_keys_urls => [set_user()] };

my $fh = CAF::FileWriter->new("target/test/ssh_url_test_1");

is($cmp->set_ssh_fromurls("foo", $u, $fh), 0,
   "SSH from URLs returns with no errors");
is("$fh", "foo bar\n", "The SSH file has the correct contents");

# cleanup $fh
$fh->close();

=pod

=head2 An empty URL list is handled correctly

The method is successful, but the file is empty.

=cut

$u->{ssh_keys_urls} = [];

$fh = CAF::FileWriter->new("target/test/ssh_url_test_2");

is($cmp->set_ssh_fromurls("foo", $u, $fh), 0,
   "SSH with empty URL list returns with no errors");
is("$fh", "", "The SSH file is empty when the URL list is empty");

=pod

=head2 The method handles naturally non-existing URL lists

This shouldn't raise any errors.

=cut

is($cmp->set_ssh_fromurls("foo", {}, $fh), 0,
   "SSH with no URL list returns with no errors");
is("$fh", "", "The SSH file is empty when there is no SSH list");
ok(!$cmp->{ERROR}, "No errors when populated authorized_hosts so far");

=pod

=head2 The method raises errors when the URLs are unreachable

=cut

$u->{ssh_keys_urls} = ["file:///kljhljhkljhljh"];

is($cmp->set_ssh_fromurls("foo", $u, $fh), -1,
   "Invalid or unreachable URLs raise an error");
is($cmp->{ERROR}, 1, "The error is reported");

=pod

=head2 The method raises an error if the file is wrong

I don't remember how this could happen, but it's better to test it
now.

=cut

is($cmp->set_ssh_fromurls("foo", $u), -1,
   "Invalid filehandle gets reported");
is($cmp->{ERROR}, 2, "The filehandle error is reported");

# close beofre DESTROY
$fh->close();

done_testing();
