use strict;
use warnings;
use Test::More;
use Test::Quattor qw(aii);
use NCM::Component::metaconfig;
use Test::MockModule;
use CAF::Object;

use JSON::XS;

=pod

=head1 DESCRIPTION

Test the aii_command method.

This is the same template as the configure method

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $cfg = get_config_for_profile('aii');

my $cache_path = $cfg->{cache_path};

is($cmp->aii_command($cfg), 1, "Configure succeeds");

my $fh = get_file("$cache_path/metaconfig/foo/bar");
ok($fh, "A file was actually created in cache_path");
isa_ok($fh, "CAF::FileWriter");

$fh = get_file("/foo/bar");
ok(!defined($fh), "Nothing created at regular file location");

ok(command_history_ok(undef, ['service foo', 'cmd']), "serivce foo not restarted, no cmd run");

done_testing();
