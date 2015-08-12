# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the generation of the crushmap with tt file


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_crushmap_tt);
use NCM::Component::ceph;
use CAF::Object;
use CAF::TextRender;
use crushdata;
use Cwd;
use Readonly;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('basic_crushmap_tt');
my $cmp = NCM::Component::ceph->new('ceph');


my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};

my $crush = $cluster->{crushmap};

my $trd = CAF::TextRender->new(
    'crush', 
    $crush, 
    relpath => 'ceph', 
    includepath => [getcwd() . "/target/share/templates/quattor"] 
);
ok($trd, "Template successfully rendered");
my $str = $trd->get_text;
# Very basic template, not filled in
is($str,$crushdata::BASEMAP, 'written crushmap ok');
ok(!$trd->{fail}, "No errors in rendering the template");

done_testing();
