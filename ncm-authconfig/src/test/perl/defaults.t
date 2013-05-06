# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the ldap/defaults.tt template.  We only ensure it renders
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
	desc => {
		bind_dn => 'bnd',
		authok_type => 'aot',
		authok => 'ao'
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/domains/ldap/defaults.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^ldap_default_bind_dn\s*=\s*bnd$}m, "bind_dn rendered correctly");


done_testing();
