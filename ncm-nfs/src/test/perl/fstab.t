use strict;
use warnings;

use Test::More;
use Test::Quattor qw(fstab);
use Test::MockModule;

use Test::Quattor::RegexpTest;

use NCM::Component::nfs;

use CAF::Object;
$CAF::Object::NoAction = 1;

set_caf_file_close_diff(1);

my $mock = Test::MockModule->new('NCM::Component::nfs');
my $dir_exists = {};
$mock->mock('_directory_exists', sub {return $dir_exists->{shift};});

my $mkdir = [];
$mock->mock('_make_directory', sub { shift; push(@$mkdir, shift)});

=head2 fstab_add_defaults

=cut

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

is_deeply(NCM::Component::nfs::fstab_add_defaults($fs1_orig), $fs1,
          "Defaults added to fs1 fstab entry");

=head2 parse_fstab_line

=cut

my $fstab = "/etc/fstab";

my $fstab_txt = <<EOF;
# Comment
# comment with ncm-nfs
/dev00 /mntpt00       ext4                special,defaults                1
/dev01 /mntpt01 ext3
/mydev0 /mount0 nfs nodefaults 10 100
/mydevX /mountX none bind
mydev1 /mount1 panfs super,awesome 50 100
# Extra trailing comment
EOF

my $fs0 =  {
    device => '/dev00',
    mountpoint => '/mntpt00',
    fstype => 'ext4',
    options => 'special,defaults',
    freq => 1,
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

my $fs4 = {
    device => "mydev1",
    mountpoint => "/mount1",
    fstype => "panfs",
    options => "super,awesome",
    freq => 50,
    passno => 100,
};


my @parsed = map {NCM::Component::nfs::parse_fstab_line($_)} split("\n", $fstab_txt);
is_deeply(\@parsed, [undef, undef, $fs0, $fs1, $fs2, $fs3, $fs4, undef],
          "fstab lines parsed as expected (comments are not added)");

=head2 fstab

Test fstab method

=cut

set_file_contents($fstab, $fstab_txt);

my $cmp = NCM::Component::nfs->new('nfs');
my $cfg = get_config_for_profile('fstab');
my $tree = $cfg->getTree($cmp->prefix());

$mkdir = [];
my ($fstab_changed, $old, $old_order, $new, $new_order) = $cmp->fstab($tree);

my $fh = get_file($fstab);
diag "modified fstab $fh";
Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/regexps/fstab',
    text => "$fh",
    )->test();

ok($fstab_changed, "fstab method returns changed state");
# Tests nfs and none/bind
is_deeply($old, { '/mydev0' => $fs2, '/mydevX' => $fs3, 'mydev1' => $fs4 }, "old hashref as expected");
is_deeply($old_order, [qw(/mydev0 /mydevX mydev1)], "old order as expected");

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
    action => 'remount',
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

is_deeply($mkdir, [qw(/mount000 /mount1 /amount2)], "fstab triggered _make_directory (no directories existed)");


=head2 do_mount

Test do_mount

=cut

set_command_status('my mount command /mymntpt', 0);
ok($cmp->do_mount([qw(my mount command)], {device => 'mydev', mountpoint => '/mymntpt'}),
   "do_mount success returns on success");
isa_ok(get_command('my mount command /mymntpt')->{object}, 'CAF::Process',
       'expected succesful command executed');

set_command_status('fail my mount command /mymntpt', 1);
ok(! defined($cmp->do_mount([qw(fail my mount command)], {device => 'mydev', mountpoint => '/mymntpt'})),
   "do_mount failure returns undef");
isa_ok(get_command('fail my mount command /mymntpt')->{object}, 'CAF::Process',
       'expected failure command executed');


=head2 process_mounts

Test process_mounts

=cut

# reset fstab
$fh->close();
$fh = undef;
set_file_contents($fstab, $fstab_txt);
command_history_reset();
my ($fstab_changed_2, $action) = $cmp->process_mounts($tree);

ok($fstab_changed_2, "process_mounts returns fstab_changed");
is($fstab_changed_2, $fstab_changed,
   "process_mounts returns fstab_changed from fstab method");
ok($action, "process_mounts returns action_taken");

ok(command_history_ok([
    qr{^umount -l /mountX$},
    qr{^umount -l /mount0$},
    qr{^mount /mount000$},
    qr{^mount -o remount /mount1$},
    qr{^mount /amount2$},
]), "correct mount commands triggered in proper order");


done_testing();
