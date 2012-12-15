# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(base);
use NCM::Component::ccm;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;

my $mock = Test::MockModule->new("CAF::FileWriter");

$mock->mock("cancel", sub {
		my $self = shift;
		*$self->{CANCELLED}++;
		*$self->{save} = 0;
	    });

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::ccm->new("ccm");

=pod

=head1 Tests for the CCM component

=cut

my $cfg = get_config_for_profile("base");

$cmp->Configure($cfg);
ok(!exists($cmp->{ERROR}), "No errors found in normal execution");
my $fh = get_file("/etc/ccm.conf");
isa_ok($fh, "CAF::FileWriter", "A file was opened");
like($fh, qr{(?:^\w+ [\w\-/\.]+$)+}m, "Lines are correctly printed");
unlike($fh, qr{^(?:version|config)}m, "Unwanted fields are removed");


set_command_status(join(" ", NCM::Component::ccm::TEST_COMMAND), 1);

$cmp->Configure($cfg);
is($cmp->{ERROR}, 1, "Failure in ccm-fetch is detected");
$fh = get_file("/etc/ccm.conf");
is(*$fh->{CANCELLED}, 2, "File contents are cancelled upon error");

done_testing();
