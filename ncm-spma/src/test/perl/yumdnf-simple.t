# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Basic yumdnf tests.

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor qw(yumdnf_simple yumdnf_simple_nomods);
use NCM::Component::spma::yumdnf;
use CAF::Object;
use Test::Quattor::Object;
use Test::MockModule;
use NCM::Component::spma;
use Readonly;
use File::Path qw(mkpath rmtree);
use Set::Scalar;

use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();

$CAF::Object::NoAction = 1;

my $obj = Test::Quattor::Object->new;

=pod

=item Test basic subclassing constants

=cut

my $cmp = NCM::Component::spma::yumdnf->new("spma", $obj);

# Test _set_yum_config
# Only the default config is active
is_deeply($cmp->_set_yum_config([qw(a b c)]),
         ['a', '-c', '/etc/dnf/dnf.conf', 'b', 'c'], "Inserted (default) yum/dnf config");


=item Test general loading of packager

=cut

my $mock = Test::MockModule->new('NCM::Component::spma::yumdnf');
$mock->mock('Configure', 'ConfigureYumdnf');

my $cfg = get_config_for_profile("yumdnf_simple");

my $cmpfull = NCM::Component::spma->new("spma");

is($cmpfull->Configure($cfg), 'ConfigureYumdnf', 'yumdnf loaded via SPMA_BACKEND');

=item test SCC handling

=cut

my $cands = Set::Scalar->new('xyz;i386', 'klm;x86_64::abc;i686', 'p1;123::p2;456');
my $wanted = Set::Scalar->new('abc', 'def');
my $rem = $cmpfull->_pkg_rem_calc($cands, $wanted);

is($rem, Set::Scalar->new('xyz;i386', 'p1;123', 'p2;456'),
   "Properly detect all scc components as single false positive and report the leftover sccs separately");


=item test modularity code

=cut

Readonly my $MODULES_DIR => "target/test/simple.modules.d";

sub initialize_modules
{
    mkpath($MODULES_DIR);
    open(FH, ">", "$MODULES_DIR/mod1.module");
    open(FH, ">", "$MODULES_DIR/mod2.module");
}

rmtree($MODULES_DIR);


is($cmpfull->modularity(0, $cfg, $MODULES_DIR), 1,
   'yumdnf modularity with moduleprocessing disabled returns 1 (instead of failing)');
is($cmpfull->modularity(1, $cfg, $MODULES_DIR), 0,
   'yumdnf modularity with moduleprocessing enabled returns 0 (modules dir is missing, cleanup fails hard)');

initialize_modules();

my $modules = {'mod1' => {}};

is($cmpfull->modularity(1, $cfg, $MODULES_DIR), 1,
   'yumdnf modularity with moduleprocessing enabled returns 1');
ok(!-e "$MODULES_DIR/mod2.module", "Unwanted module scheduled for removal");
ok(-e "$MODULES_DIR/mod1.module", "Wanted module kept");  # content is not what you want

my $head = "# File generated by NCM::Component::spma::yumdnf. Do not edit\n";

my $fh = get_file("$MODULES_DIR/mod1.module");
is("$fh", "${head}[mod1]\nname=mod1\nstream=abc\nprofiles=\nstate=enabled\n", "mod1 module content ok");
$fh = get_file("$MODULES_DIR/mod3.module");
is("$fh", "${head}[mod3]\nname=mod3\nstream=def\nprofiles=\nstate=disabled\n", "mod3 module content ok");

done_testing();


=pod

=back

=cut
