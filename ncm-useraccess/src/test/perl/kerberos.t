#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::Quattor;
use Test::More;
use Cwd;
use NCM::Component::useraccess;
use CAF::Object;
use Readonly;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<set_ssh_fromkeys> method.

=head1 TESTS

=head2 An key from an accessible URL is retrieved

This is the basic, usual case.

=cut

my $u = {
	 kerberos4 => [ {
			 realm => "RE.ALM",
			 principal => "me"
			},
			{
			 realm => "RE.A.LM",
			 principal => "somebody",
			 instance => "inst",
			}
		      ]
	};

my $cmp = NCM::Component::useraccess->new("useraccess");


my $fh = CAF::FileWriter->new("target/test/kerberos_1");
my $fhs = {
	   "kerberos4" => $fh,
	  };

is($cmp->set_kerberos("foo", $u, $fhs), 0,
   "Kerberos4 settings returns with no errors");
like("$fh", qr{^me\@RE.ALM$}m,
     "Instanceless entry correctly generated");
like("$fh", qr{^somebody.inst\@RE.A.LM$}m,
     "Entry with isntance field correctly generated");

# close the filehandles before DESTROY (there's a reference kept in $fhs)
$fh->close();

$fh = CAF::FileWriter->new("target/test/kerberos_2");
is($cmp->set_ssh_fromurls("foo", $u, $fh), 0,
   "SSH with empty key list returns with no errors");
is("$fh", "", "The SSH file is empty when the key list is empty");

=pod

=head2 Errors are gracefully handled and reported

=cut

is($cmp->set_kerberos("foo", $u, {}), -1,
   "Error raisen when there are no files to write to");
is($cmp->{ERROR}, 1, "Error is correctly reported");

is($cmp->set_kerberos("foo", {}, {}), 0,
   "Non-existing Kerberos lists handled successfully");

# close the filehandles before DESTROY
$fh->close();

done_testing();

