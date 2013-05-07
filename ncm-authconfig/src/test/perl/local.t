# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the domains/local.tt template.  We only ensure it renders
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
	    default_shell => "/bin/bash"
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/domains/local.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^default_shell\s*=\s*/bin/bash}m, "Sample field rendered correctly");

done_testing();
