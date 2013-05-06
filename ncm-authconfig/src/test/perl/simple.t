# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the simple.tt template.  We only ensure it renders something
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
		allow_users => [qw(u1 u2)]
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/domains/simple.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^simple_allow_users\s*=\s*u1,\s*u2$}m, "Sample field rendered correctly");

done_testing();
