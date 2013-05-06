# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the ldap/autofs.tt template.  We only ensure it renders something
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
		map_name => 'mn'
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/domains/ldap/autofs.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^ldap_autofs_map_name\s*=\s*mn$}m, "Sample field rendered correctly");

done_testing();
