use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simple);
use NCM::Component::metaconfig;
use Test::MockModule;
use CAF::Object;

use JSON::XS;

my $mock = Test::MockModule->new('NCM::Component::metaconfig');

=pod

=head1 DESCRIPTION

Test the configure() method.

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $cfg = get_config_for_profile('simple');

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file("/foo/bar");
ok($fh, "A file was actually created");
isa_ok($fh, "CAF::FileWriter");


done_testing();
