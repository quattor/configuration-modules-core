use strict;
use warnings;
use Test::More;

use NCM::Component::nfs;

my $orig = {
    device => 'dev',
    mntpt => 'mnt',
    fstype => 'typ',
    opt => 'options',
    freq => 0,
    passno => 1,
};

my $new = { %$orig };
is(NCM::Component::nfs::compare_entries($orig, $new),
   0, 'Comparing equal hashes returns 0');

$new = { %$orig };
$new->{device} = 'otherdev';
is(NCM::Component::nfs::compare_entries($orig, $new),
   1, 'Different devices returns 1');

$new = { %$orig };
$new->{mntpt} = 'othermnt';
is(NCM::Component::nfs::compare_entries($orig, $new),
   1, 'Different mntpt returns 1');

$new = { %$orig };
$new->{fstype} = 'othertyp';
is(NCM::Component::nfs::compare_entries($orig, $new),
   2, 'Different fstype returns 2');

$new = { %$orig };
$new->{opt} = 'otheroption';
is(NCM::Component::nfs::compare_entries($orig, $new),
   2, 'Different opt returns 2');

$new = { %$orig };
$new->{freq} = 100;
is(NCM::Component::nfs::compare_entries($orig, $new),
   2, 'Different freq returns 2');

$new = { %$orig };
$new->{passno} = 200;
is(NCM::Component::nfs::compare_entries($orig, $new),
   2, 'Different passno returns 2');


done_testing;
