# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the ldap/krb5.tt template.  We only ensure it renders something
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
		keytab => 'kt'
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/domains/ldap/krb5.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^ldap_krb5_keytab\s*=\s*kt$}m, "Sample field rendered correctly");

done_testing();
