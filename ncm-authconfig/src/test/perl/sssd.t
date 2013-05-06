# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the top-level sssd.tt template.  We only ensure it renders
something and there are no errors.

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::authconfig;

my $cmp = NCM::Component::authconfig->new("authconfig");

my $t = {
    ldap => {
	foo => {
	    uri => ['u1']
	    }
	},
    simple => {
	bar => {
	    allow_users => ['us1']
	}
    }
};


my $str;

ok($cmp->template()->process('authconfig/sssd.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^\[domain/foo\]$}m, "LDAP domain name printed");
like($str, qr{^ldap_uri\s*=\s*u1$}m, "LDAP fields printed");
like($str, qr{^\[domain/bar\]$}m, "Simple domain name printed");
like($str, qr{^simple_allow_users\s*=\s*us1$}m, "Simple fields printed");

done_testing();
