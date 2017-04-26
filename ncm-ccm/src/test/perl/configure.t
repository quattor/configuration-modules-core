# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(base_accounts base_no_ncm_accounts);
use NCM::Component::ccm;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;
use Test::Quattor::RegexpTest;


my $ccmconf = "/etc/ccm.conf";
my $mock = Test::MockModule->new("CAF::FileWriter");

my $cancelled = 0;
$mock->mock("cancel", sub {
    $cancelled++ if ref($_[0]) ne 'CAF::FileReader';
    return $mock->original('cancel')->(@_);
});

my $tmppath;
my $mock_ccm = Test::MockModule->new("NCM::Component::ccm");
$mock_ccm->mock('tempdir', sub { mkdir($tmppath); return $tmppath; });

my $cmp = NCM::Component::ccm->new("ccm");


=head1

Compilation of base_no_ncm_accounts implies that defined_group is ok to use

The compilation already happens at import, just need to make sure it was imported

=cut

my $cfg = get_config_for_profile("base_no_ncm_accounts");
is($cfg->getTree('/software/components/ccm/group_readable'), 'theadmins', 'group_readable without ncm-accounts');


=head1 Tests for the CCM component

=cut

$cfg = get_config_for_profile("base_accounts");

$tmppath = "target/ncm-ccm-test1";
$cancelled = 0;
$cmp->Configure($cfg);
ok(!exists($cmp->{ERROR}), "No errors found in normal execution");
my $fh = get_file($ccmconf);
isa_ok($fh, "CAF::FileWriter", "A file was opened");
is($cancelled, 0, "File written");

like($fh, qr{(?:^\w+ [\w\-/\.]+$)+}m, "Lines are correctly printed");
unlike($fh, qr{^(?:version|config)}m, "Unwanted fields are removed");

diag "$fh";
Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/regexps/ccm_conf',
    text => "$fh",
    )->test();


my $tstcmd = get_command(join(" ", NCM::Component::ccm::TEST_COMMAND, "$tmppath/$ccmconf"));
isa_ok($tstcmd->{object}, 'CAF::Process', "Test command found");
my $tmpfh = get_file("$tmppath/$ccmconf");
isa_ok($tmpfh, "CAF::FileWriter", "A tmp file was opened");
is("$tmpfh", "$fh", "config and tmp files have same content");

$tmppath = "target/ncm-ccm-test2";
set_command_status(join(" ", NCM::Component::ccm::TEST_COMMAND, "$tmppath/$ccmconf"), 1);

is(scalar(grep(m{ccm-fetch|cfgfile}, NCM::Component::ccm::TEST_COMMAND)), 2,
   "Expected arguments passed to ccm-fetch");

$cancelled = 0;
$cmp->Configure($cfg);
is($cmp->{ERROR}, 1, "Failure in ccm-fetch is detected");
$fh = get_file("/etc/ccm.conf");
is($cancelled, 1, "File contents are cancelled upon error");

done_testing();
