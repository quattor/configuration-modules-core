# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the services/nss.tt template.  We only ensure it renders
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
	    enum_cache_timeout => 1
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/services/nss.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^enum_cache_timeout\s*=\s*1}m, "Sample field rendered correctly");

done_testing();
