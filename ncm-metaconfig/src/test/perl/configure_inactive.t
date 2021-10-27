use strict;
use warnings;
use Test::More;
use Test::Quattor qw(configure_inactive);
use NCM::Component::metaconfig;

=pod

=head1 DESCRIPTION

Test the configure() method.

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $cfg = get_config_for_profile('configure_inactive');

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file("/foo/bar");
ok(!defined($fh), "Nothing was actually created");

done_testing();
