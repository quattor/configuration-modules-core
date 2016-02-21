use strict;
use warnings;

use Test::More;
use Test::Quattor qw(fstab);

use Test::Quattor::RegexpTest;

use NCM::Component::nfs;

use CAF::Object;
$CAF::Object::NoAction = 1;

set_caf_file_close_diff(1);

my $fstab = "/etc/fstab";

my $fstab_txt = <<EOF;
# Comment
# comment with ncm-nfs
/dev00 /mntpt00       ext4                special,defaults                1
/dev01 /mntpt01 ext3
/mydev0 /mount0 nfs nodefaults 10 100
/mydevX /mountX none bind

EOF

my $fs0 =  {
    device => '/dev00',
    mountpoint => '/mntpt00',
    fstype => 'ext4',
    options => 'special,defaults',
    freq => 1,
    passno => 0,
};

# Entry from fstab, i.e. without defaults
my $fs1_orig = {
    device => '/dev01',
    mountpoint => '/mntpt01',
    fstype => 'ext3',
};

my $fs1 = {
    device => '/dev01',
    mountpoint => '/mntpt01',
    fstype => 'ext3',
    options => 'defaults',
    freq => 0,
    passno => 0,
};

my $fs2 = {
    device => '/mydev0',
    mountpoint => '/mount0',
    fstype => 'nfs',
    options => 'nodefaults',
    freq => 10,
    passno => 100,
};

my $fs3 = {
    device => '/mydevX',
    mountpoint => '/mountX',
    fstype => 'none',
    options => 'bind',
    freq => 0,
    passno => 0,
};

is_deeply(NCM::Component::nfs::fstab_add_defaults($fs1_orig), $fs1,
          "Defaults added to fs1 fstab entry");

# The map eats undef (so the comment lines do not show up in the @parsed)
my @parsed = map {NCM::Component::nfs::parse_fstab_line($_)} split("\n", $fstab_txt);
is_deeply(\@parsed, [$fs0, $fs1, $fs2, $fs3],
          "fstab lines parsed as expected (comments are not added)");

set_file_contents($fstab, $fstab_txt);

my $cmp = NCM::Component::nfs->new('nfs');
my $cfg = get_config_for_profile('fstab');
my $tree = $cfg->getTree($cmp->prefix());

my ($fstab_changed, $old, $old_order, $new, $new_order) = $cmp->fstab($tree);

my $fh = get_file($fstab);
diag "modified fstab $fh";
Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/regexps/fstab',
    text => "$fh",
    )->test();

ok($fstab_changed, "fstab method returns changed state");
# Tests nfs and none/bind
is_deeply($old, { '/mydev0' => $fs2, '/mydevX' => $fs3 }, "old hashref as expected");
is_deeply($old_order, [qw(/mydev0 /mydevX)], "old order as expected");

my $nfs0 = {
    device => "/mydev0",
    mountpoint => "/mount000",
    fstype => "nfs",
    options => 'defaults',
    freq => 0,
    passno => 0,
    action => 'umount/mount',
};

my $nfs1 = {
    device => "mydev1",
    mountpoint => "/mount1",
    fstype => "panfs",
    options => "super,awesome",
    freq => 5,
    passno => 100,
    action => 'mount',
};

my $nfs2 = {
    device => "amydev2",
    mountpoint => "/amount2",
    fstype => "none",
    options => "bind",
    freq => 0,
    passno => 0,
    action => 'mount',
};

is(NCM::Component::nfs::mount_action_new_old($nfs0, $fs2),
   'umount/mount', 'Different mountpoint returns umount/mount');

is_deeply($new, { '/mydev0' => $nfs0, mydev1 => $nfs1, amydev2 => $nfs2 },
          "new hashref as expected");
is_deeply($new_order, [qw(/mydev0 mydev1 amydev2)], "new order as expected");

done_testing();
