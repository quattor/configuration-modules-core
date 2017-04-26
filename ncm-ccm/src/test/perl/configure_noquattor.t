# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(base_noquattor);
use NCM::Component::ccm;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;

my $mock = Test::MockModule->new("CAF::FileWriter");

my $cancelled = 0;
$mock->mock("cancel", sub {
    $cancelled++ if ref($_[0]) ne 'CAF::FileReader';
    return $mock->original('cancel')->(@_);
});

my $mock_ccm = Test::MockModule->new("NCM::Component::ccm");

# test presence of NOQUATTOR file: return true
$mock_ccm->mock("_is_noquattor", 1);

my $cmp = NCM::Component::ccm->new("ccm");

=pod

=head1 Tests for the CCM component with NOQUATTOR set

=cut

my $cfg = get_config_for_profile("base_noquattor");

$cancelled = 0;
$cmp->Configure($cfg);
my $fh = get_file("/etc/ccm.conf_noquattor");
isa_ok($fh, "CAF::FileWriter", "A file was opened");

# first test: no file present (will use generated content to test
# if file is present).

is($cancelled, 1, "File contents are cancelled with NOQUATTOR");

is($cmp->{ERROR}, 1, "Error raised because content changed and NOQUATTOR set");

# same tests as regular configure
isa_ok($fh, "CAF::FileWriter", "A file was opened");
like($fh, qr{(?:^\w+ [\w\-/\.]+$)+}m, "Lines are correctly printed");
unlike($fh, qr{^(?:version|config)}m, "Unwanted fields are removed");

# set the contents for 2nd test
set_file_contents("/etc/ccm.conf_noquattor", "$fh");
# destroy the 1st FileWriter instance
$fh = undef;

$cancelled = 0;
$cmp->{ERROR} = 0;
$cmp->Configure($cfg);
my $fh2 = get_file("/etc/ccm.conf_noquattor");
isa_ok($fh2, "CAF::FileWriter", "A file was opened");

is($cancelled, 1, "File contents are cancelled with NOQUATTOR");
is($cmp->{ERROR}, 0, "No error raised because content did not change and NOQUATTOR set");

# ccm-fetch is used as a regexp by command_history_ok, no need for exact command
ok(! command_history_ok(["ccm-fetch"]), "ccm-fetch was not called at any point");

done_testing();
