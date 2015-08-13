use strict;
use warnings;

use Test::Quattor;
use Test::More;
use NCM::Component::spma::yum;
use CAF::Object;
use File::Path qw(rmtree);


$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma::yum->new("spma");

=head1

Test noaction false : return empty string

=cut

is($cmp->noaction_prefix(0), '', "noaction_prefix with noaction=false returns empty string");


=head1

Test noaction true: make tempdir, copy relevant files, set permissions

=cut

my $prefix = $cmp->noaction_prefix(1);
my $template_regexp = qr{^/tmp/spma-noaction-};

like($prefix, $template_regexp, "noaction_prefix returns prefix $prefix according to the template");
like($prefix, qr{/$}, "noaction_prefix returns prefix $prefix ending on /");


# cleanup the prefix test tree
if($prefix =~ m/$template_regexp/) {
    rmtree($prefix);
    ok(! -d $prefix, "prefix $prefix removed");
} else {
    ok(0, "prefix $prefix not cleaned up dir due unexpected name");
}

done_testing();
