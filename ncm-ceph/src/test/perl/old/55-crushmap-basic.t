# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test generating crushmap from quattor, comparing and writing to file

=cut


use strict;
use warnings;
use File::Temp qw(tempdir);
use Test::More;
use Test::Deep;
use Test::MockModule;
use Test::Quattor qw(basic_crushmap);
use NCM::Component::ceph;
use CAF::Object;
use CAF::TextRender;
use crushdata;
use Cwd;
use Readonly;
use File::Touch;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('basic_crushmap');
my $cmp = NCM::Component::ceph->new('ceph');

set_desired_output("/usr/bin/ceph -f json --cluster ceph osd crush dump", $crushdata::CRUSHMAP_01);

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};

$cmp->use_cluster();
my $mapping = {};
my $gvalues = { mapping => $mapping };
my $crush = $cluster->{crushmap};
while (my ($hostname, $host) = each(%{$cluster->{osdhosts}})) {
    $cmp->structure_osds($hostname, $host); # Is normally done in the daemon part
    while (my ($osdkey, $osd) = each(%{$host->{osds}})) {
        $cmp->add_to_mapping($mapping, 'osd.0', $hostname, $osd->{osd_path});
    }
}
$cmp->quat_crush($crush, $cluster->{osdhosts}, $gvalues);
cmp_deeply($crush, \%crushdata::QUATMAP, 'hash from quattor built');
my $crushdir = tempdir(CLEANUP => 1);
$cmp->init_git($crushdir);
touch("$crushdir/crushmap");
my $chash = $cmp->ceph_crush($crushdir);
cmp_deeply($chash, \%crushdata::CEPHMAP, 'hash from ceph built');
$crush->{devices} = $chash->{devices}; # resolved on live system
$cmp->cmp_crush($chash, $crush);
cmp_deeply($crush, \%crushdata::CMPMAP, 'hash after compare and ids built');

Readonly my $INCLUDEPATH => [getcwd() . "/target/share/templates/quattor"] ;
my $trd = CAF::TextRender->new(
    'crush', 
    $crush, 
    relpath => 'ceph', 
    includepath => $INCLUDEPATH,
);
my $str = $trd->get_text;

# Full crushmap test, but device items not completely mocked (have all id 0)
is($str,$crushdata::WRITEMAP, 'written crushmap ok');
ok(!$trd->{fail}, "No errors in rendering the template");

my $tempdir = tempdir(CLEANUP => 1); 

my $mock = Test::MockModule->new('CAF::TextRender');
my $mockc = Test::MockModule->new('NCM::Component::Ceph::commands');


$mock->mock('new', sub {
    my $init = $mock->original("new");
    my $trd = &$init(@_);
    $trd->{includepath} = $INCLUDEPATH;
    return $trd;
});

$mockc->mock('git_commit', 1);

ok($cmp->write_crush($crush, $tempdir), "Generated crushmap");

done_testing();
