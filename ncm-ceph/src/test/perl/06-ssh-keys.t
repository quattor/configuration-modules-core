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
my $scancmd = 'su - ceph -c /usr/bin/ssh-keyscan ceph001.cubone.os';
set_desired_output($scancmd, "I am the key, I am the key!\n");

my $cephusr = { homeDir => '/foo', uid => 1234, gid => 1234 };
$cmp->ssh_known_keys($hostname, 'first', $cephusr);
my $cmd = get_command($scancmd);
ok(!defined($cmd), "key found, no key added");

set_desired_output($keyfind, '');# no key
set_file_contents("/foo/.ssh/known_hosts", 
    "The setting sun with the last light of Durins Day will shine upon the key-hole\n");
$cmp->ssh_known_keys($hostname, 'first', $cephusr);

$cmd = get_command($scancmd);
ok(defined($cmd), "add new key");
# Call the function that will manipulate /etc/passwd here.
my $fh = get_file("/foo/.ssh/known_hosts");
is("$fh", "I am the key, I am the key!\nThe setting sun with the last light of Durins Day will shine upon the key-hole\n", 
    "The file has received the expected contents");
is(*$fh->{options}->{owner}, '1234', "The file has the expected owner");
is(*$fh->{options}->{group}, '1234', "The file has the expected group");

done_testing();
