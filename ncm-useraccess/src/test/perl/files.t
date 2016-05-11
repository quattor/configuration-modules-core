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

=pod

=head1 DESCRIPTION

Test the C<files> method, ensuring that all the file handles for the
user are properly created, and that the correct managed credentials
are specified.

=cut


my $u = {
	 managed_credentials => []
	};

my $cmp = NCM::Component::useraccess->new("useraccess");
my $h = $cmp->files($u, 0, 0, $HOME);
is(*{$h->{kerberos4}}->{filename}, "$HOME/.klogin",
   "Correct Kerberos4 file defined");
is(*{$h->{kerberos5}}->{filename}, "$HOME/.k5login",
   "Correct Kerberos5 file defined");
is(*{$h->{ssh_keys}}->{filename}, "$HOME/.ssh/authorized_keys",
   "Correct SSH keys file defined");
is(scalar(keys(%{$h->{managed_credentials}})), 0,
   "Empty credentials to manage");

$u->{managed_credentials} = [qw(foo bar)];
$h = $cmp->files($u, 0, 0, $HOME);

is(scalar(keys(%{$h->{managed_credentials}})), 2,
   "Correct set of credentials to manage");

$cmp->close_files($h);

done_testing();
