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
	dict => {
	    justastring => 'astring',
        list => [1, 2],
        colonlist => [1, 2],
        boolfalse => 0,
        booltrue => 1,
        exclude => 'somevalue'
	},
	list => ['list'],
    colonlist => ['colonlist'],
    bool => ['boolfalse','booltrue'],
    exclude => ['exclude']
};

my $str;

ok($cmp->template()->process('authconfig/generic.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^list\s*=\s*1,\s*2$}m, "Sample list field rendered correctly");
like($str, qr{^colonlist\s*=\s*1:\s*2$}m, "Sample colonlist field rendered correctly");
like($str, qr{^justastring\s*=\s*astring$}m, "Sample justastring field rendered correctly");
like($str, qr{^boolfalse\s*=\s*False$}m, "Sample boolean false field rendered correctly");
like($str, qr{^booltrue\s*=\s*True$}m, "Sample boolean true field rendered correctly");
unlike($str, qr{^exclude\s*=\s*somevalue$}m, "Sample field excluded correctly");

done_testing();
