use strict;
use warnings;
use Test::More;
use Test::Quattor qw(configure commands);
use NCM::Component::metaconfig;

=pod

=head1 DESCRIPTION

Test the configure() method.

=cut


my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $cfg = get_config_for_profile('configure');

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file("/foo/bar");
ok($fh, "A file was actually created");
isa_ok($fh, "CAF::FileWriter");

# if default sysv init service changes, also modify the aii_command negative test
ok(command_history_ok(['service foo restart']), "serivce foo restarted");

done_testing();
