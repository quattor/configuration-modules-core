use strict;
use warnings;
use Test::More;
use Test::Quattor;

use NCM::Component::nfs;

my $orig = {
    device => 'dev',
    mountpoint => 'mnt',
    fstype => 'typ',
    options => 'options',
    freq => 0,
    passno => 1,
};

my $new = { %$orig };
is(NCM::Component::nfs::mount_action_new_old($new, undef),
   'mount', 'Comparing new vs undef returns mount');

$new = { %$orig };
is(NCM::Component::nfs::mount_action_new_old($new, $orig),
   'none', 'Comparing equal hashes returns none');

$new = { %$orig };
$new->{action} = 'dosomething';
is(NCM::Component::nfs::mount_action_new_old($new, $orig),
   'none', 'Comparing hashes returns none is action attribute is different');

$new = { %$orig };
$new->{device} = 'otherdev';
is(NCM::Component::nfs::mount_action_new_old($new, $orig),
   'umount/mount', 'Different devices returns umount/mount');

$new = { %$orig };
$new->{mountpoint} = 'othermnt';
is(NCM::Component::nfs::mount_action_new_old($new, $orig),
   'umount/mount', 'Different mntpt returns umount/mount');

$new = { %$orig };
$new->{fstype} = 'othertyp';
is(NCM::Component::nfs::mount_action_new_old($new, $orig),
   'remount', 'Different fstype returns remount');

$new = { %$orig };
$new->{options} = 'otheroption';
is(NCM::Component::nfs::mount_action_new_old($new, $orig),
   'remount', 'Different opt returns remount');

$new = { %$orig };
$new->{freq} = 100;
is(NCM::Component::nfs::mount_action_new_old($new, $orig),
   'remount', 'Different freq returns remount');

$new = { %$orig };
$new->{passno} = 200;
is(NCM::Component::nfs::mount_action_new_old($new, $orig),
   'remount', 'Different passno returns remount');


done_testing;
