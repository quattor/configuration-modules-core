# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the global.tt template.  We only ensure it renders something and
there are no errors.

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
	    services => [1, 2]
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/global.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^services\s*=\s*1,\s*2$}m, "Sample field rendered correctly");

done_testing();
