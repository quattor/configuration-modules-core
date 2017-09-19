use strict;
use warnings;

use Test::Quattor;
use Test::Quattor::Object;
use Test::Quattor::Filetools qw(readfile);
use Test::More;
use NCM::Component::network;
use Readonly;

my $obj = Test::Quattor::Object->new();

my $cmp = NCM::Component::network->new();

set_desired_output('ip addr show', readfile('src/test/resources/output/ipaddrshow_el5'));
my $res = $cmp->make_dev2mac();
is_deeply($res, {'eth0' => '02:00:0a:8d:32:90'}, "dev2mac with el5");

set_desired_output('ip addr show', readfile('src/test/resources/output/ipaddrshow'));
my $res2 = $cmp->make_dev2mac();
is_deeply($res2, {
    'br100' => 'bc:30:5b:a9:3d:30',
    'em1' => 'bc:30:5b:a9:3d:2e',
    'em1.295' => 'bc:30:5b:a9:3d:2e',
    'em2' => 'bc:30:5b:a9:3d:30',
    'em3' => 'bc:30:5b:a9:3d:32',
    'em4' => 'bc:30:5b:a9:3d:34',
    'one-324-0' => 'fe:01:00:80:10:08',
    'one-324-1' => 'fe:01:00:80:10:09',
    'one-370-0' => 'fe:01:00:80:0a:20',
    'one-370-1' => 'fe:01:00:80:0a:21',
    'one-385-0' => 'fe:01:00:80:0a:0c',
    'one-385-1' => 'fe:01:00:80:0a:0d',
    'ovs-system' => '1a:97:90:0f:30:21'
}, "dev2mac with el7");

done_testing();
