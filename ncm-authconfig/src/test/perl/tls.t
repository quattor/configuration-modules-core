# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the ldap/tls.tt template.  We only ensure it renders something
and there are no errors.

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::authconfig;

my $cmp = NCM::Component::authconfig->new("authconfig");

my $t = {
	desc => {
		cacert => 'ca',
		cipher_suite => [qw(c1 c2)]
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/domains/ldap/tls.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^ldap_tls_cacert\s*=\s*ca$}m, "Sample field rendered correctly");
like($str, qr{^ldap_tls_cipher_suite\s*=\s*c1:c2$}m, "Cipher suite rendered correctly");

done_testing();
