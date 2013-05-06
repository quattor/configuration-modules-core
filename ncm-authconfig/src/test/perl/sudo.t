# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the ldap/sudo.tt template.  We only ensure it renders something
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
		search_base => 'sb',
		rules => { object_class => 'oc' }
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/domains/ldap/sudo.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^ldap_sudo_search_base\s*=\s*sb$}m, "Sample field rendered correctly");
like($str, qr{^ldap_sudorule_object_class\s*=\s*oc$}m,
     "Sample sudo rule rendered correctly");

done_testing();
