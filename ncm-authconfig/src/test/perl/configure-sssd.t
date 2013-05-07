# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<configure_sssd> method.

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::authconfig;
use CAF::FileWriter;
use CAF::Object;
use Test::MockModule;
use Readonly;

$CAF::Object::NoAction = 1;

my $close_return;

Readonly my $SSSD_FILE => NCM::Component::authconfig::SSSD_FILE();
Readonly my $RESTART_CMD => "/sbin/service sssd restart";
Readonly my $TT_FILE => NCM::Component::authconfig::TT_FILE;

my $mock = Test::MockModule->new("CAF::FileWriter");

$mock->mock("close", sub {
		my ($self) = @_;
		return $close_return;
	    });


my $cmp = NCM::Component::authconfig->new("authconfig");

=pod

=head2 Simple run

The file is opened and the daemon is restarted.

=cut

$close_return = 1;

ok($cmp->configure_sssd({}, $SSSD_FILE, $TT_FILE),
   "First call changes something");

my $fh = get_file($SSSD_FILE);

isa_ok($fh, "CAF::FileWriter", "File was opened");

is(*$fh->{options}->{mode}, 0600, "File has correct permissions");

my $cmd = get_command($RESTART_CMD);

ok($cmd, "Daemon was restarted");

ok(!$cmp->{ERROR}, "No errors reported in basic execution");

=pod

=head2 Error conditions

How the component handles its internal errors.

=over

=item * The restart command fails

=cut

set_command_status($RESTART_CMD, 1);

$cmp->configure_sssd({}, $SSSD_FILE, $TT_FILE);

is($cmp->{ERROR}, 1, "Errors reported when the restart fails");

set_command_status($RESTART_CMD, 0);

=pod

=item * The template cannot be rendered correctly

=cut

$close_return = 0;

$cmp->configure_sssd({}, $SSSD_FILE, "8o76yo78tgog");

is($cmp->{ERROR}, 2, "Error while rendering the template is reported");

done_testing();
