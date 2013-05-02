# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Trivial tests for the several methods that add arguments to the
C<authconfig> invocation.

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::authconfig;
use CAF::Process;

my $cmp = NCM::Component::authconfig->new("authconfig");

my $cmd = CAF::Process->new([]);



$cmp->enable_krb5({realm => "foo", adminservers => [qw(admin admin2)],
		   kdcs => [qw(kdc kdc2)]}, $cmd);

is($cmd->{COMMAND}->[0], "--enablekrb5", "KRB5 enabled");
is($cmd->{COMMAND}->[1], "--krb5realm", "KRB5 realm invoked");
is($cmd->{COMMAND}->[2], "foo", "Correct KRB5 realm passed");
is($cmd->{COMMAND}->[3], "--krb5kdc", "KRB5 KDCs defined");
is($cmd->{COMMAND}->[4], "kdc,kdc2", "Correct KDCs defined");
is($cmd->{COMMAND}->[5], "--krb5adminserver", "KRB5 adminserver defined");
is($cmd->{COMMAND}->[6], "admin,admin2", "Correct admin servers defined");

$cmd = CAF::Process->new([]);
$cmp->enable_krb5({realm => "foo"}, $cmd);
is($cmd->{COMMAND}->[0], "--enablekrb5", "KRB5 enabled inconditionally");
is($cmd->{COMMAND}->[1], "--krb5realm", "KRB5 realm enabled inconditionally");
ok(!grep(m{krb5admin|krb5kdc}, @{$cmd->{COMMAND}}),
   "KRB5 KDC and admins are not passed unless defined");

done_testing();
