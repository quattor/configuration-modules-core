use strict;
use warnings;
use Test::More;
use Test::Quattor qw(configure);
use NCM::Component::sysconfig;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::sysconfig->new('sysconfig');
my $cfg = get_config_for_profile('configure');

# Set up list of previously managed files
set_file_contents('/etc/sysconfig/ncm-sysconfig', "/etc/sysconfig/delete_me\n/etc/sysconfig/examplefile\n");

# Set up existing files with garbage contents
set_file_contents('/etc/sysconfig/delete_me', "DELETE_ME=delete_me\n");
set_file_contents('/etc/sysconfig/examplefile', "NOPE=nope_nope\n");

is($cmp->Configure($cfg), 1, "Does the component run correctly with a test profile?");

isa_ok(get_file('/etc/sysconfig/ncm-sysconfig'), "CAF::FileWriter", "Is the file-handle for the list of managed files the correct class?");
is(get_file_contents('/etc/sysconfig/ncm-sysconfig'), "/etc/sysconfig/examplefile\n", "Is the list of managed files updated correctly?");

is(get_file_contents('/etc/sysconfig/delete_me'), undef, "Has the previously managed file been deleted?");

isa_ok(get_file('/etc/sysconfig/examplefile'), "CAF::FileWriter", "Is the file-handle for the example file the correct class?");
is(get_file_contents('/etc/sysconfig/examplefile'), "key1=testvalue\nkey2=valuetest\n", "Does the example file have the correct contents?");

done_testing();
