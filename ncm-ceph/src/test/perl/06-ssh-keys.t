# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the ssh_known_keys method

=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_cluster);
use NCM::Component::ceph;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};

$cmp->use_cluster();
my $is_deploy = 1;
my $hostname = 'ceph001.cubone.os';
my $keyfind = "su - ceph -c /usr/bin/ssh-keygen -F ceph001.cubone.os";
set_desired_output($keyfind, "I am a key, I am a key!\n");# key visible

$cmp->ssh_known_keys($hostname, 'first');
my $scancmd = 'su - ceph -c /usr/bin/ssh-keyscan ceph001.cubone.os >> ~/.ssh/known_hosts';
my $cmd = get_command($scancmd);
ok(!defined($cmd), "key found, no key added");

set_desired_output($keyfind, '');# no key
$cmp->ssh_known_keys($hostname, 'first');

$cmd = get_command($scancmd);
ok(defined($cmd), "add new key");

done_testing();
