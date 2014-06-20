# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(base);
use NCM::Component::cdp;
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

my $cmp = NCM::Component::cdp->new("cdp");

=pod

=head1 Tests for the CDP component

=cut

my $cfg = get_config_for_profile("base");

$cmp->Configure($cfg);
ok(!exists($cmp->{ERROR}), "No errors found in normal execution");
my $fh = get_file("/etc/cdp-listend.conf");
isa_ok($fh, "CAF::FileWriter", "A file was opened");
like($fh, qr{(?:^\w+\s*=\s*[\w\-/\.]+$)+}m, "Lines are correctly printed");
unlike($fh, qr{^(?:version|config)}m, "Unwanted fields are removed");

like($fh, qr{^fetch_offset\s*=\s*5\s*$}m, "Correct fetch_offset line");
like($fh, qr{^fetch_smear\s*=\s*8\s*$}m, "Correct fetch_smear line");
like($fh, qr{^nch_smear\s*=\s*10\s*$}m, "Correct nch_smear line");
like($fh, qr{^port\s*=\s*7777\s*$}m, "Correct port line");

done_testing();
