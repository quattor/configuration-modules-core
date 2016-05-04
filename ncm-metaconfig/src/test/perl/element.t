use strict;
use warnings;

use Test::Quattor::ProfileCache qw(set_json_typed get_json_typed);
BEGIN {
    set_json_typed()
}

use Test::More;
use Test::Quattor qw(element);
use NCM::Component::metaconfig;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $cfg = get_config_for_profile('element');

is($cmp->Configure($cfg), 1, "Configure succeeds");

my $fh = get_file("/foo/bar");
is("$fh", "boolean=1\nstring=mystring\n\n", "tiny with no element conversion as expected");

my $fh2 = get_file("/foo/bar2");
is("$fh2", "boolean=TRUE\nlist='a','b'\nstring='mystring'\n\n", "tiny with element conversion as expected");

done_testing();
