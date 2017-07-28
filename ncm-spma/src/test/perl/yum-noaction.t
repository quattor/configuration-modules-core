# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;
use Test::More;
use Readonly;
use Test::Quattor qw(noaction);
use CAF::Object;
use CAF::FileWriter;
use CAF::FileEditor;
use File::Path qw(mkpath rmtree);
use File::Basename;
use Test::MockModule;
use File::Temp qw (tempdir);
use NCM::Component::spma::yum;
use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();


use Cwd;
Readonly my $TESTDIR => getcwd().'/target/test';

my $error = '';
my $mock = Test::MockModule->new('NCM::Component::spma::yum');
$mock->mock('error', sub {
    my ($self, @args) = @_;
    $error = join('', @args);
    return $mock->original('error')->($self, @args);
});

# Set NoAction
$NCM::Component::spma::yum::NoAction = 1;
$CAF::Object::NoAction = 1;
# TODO: rework the unittests to use NoAction-safe Test::Quattor since 1.54
#       switch to CAF::Path and rely on get_file for file existence tests
#       do not use these lightly
$Test::Quattor::NoAction = 0;
$Test::Quattor::Original = 1;

my $cmp = NCM::Component::spma::yum->new("spma");

mkpath($TESTDIR) if ! -d $TESTDIR;

is(NCM::Component::spma::yum::NOACTION_TEMPDIR_TEMPLATE,
   "/tmp/spma-noaction-XXXXX",
   "NOACTION_TEMPDIR_TEMPLATE");

Readonly my $MOCKED_TEMPLATE => "$TESTDIR/spma-noaction-XXXXX";

=pod

=head1 What to test

=over

=item _copy_files_and_dirs

files/dirs are copied, permissions on tmppath are restricted

=cut

# can't mock the -f/-e/-d tests, must create actual structure
# make test structure in target, should be replicated
sub mkfile {
    my $filename = shift;
    diag "mkfile $filename";
    mkpath(dirname($filename));
    open(my $fh, '>', $filename);
    print $fh "$filename\n";
    close($fh);
}

# can't use CAF::FileReader.
# the fact that this can be read with open means that it was actually written,
# i.e. the _override_noaction_fh did it's work
sub readfile
{
    my $fn = shift;
    return if ! -f $fn;
    open(my $fh, $fn);
    my $txt = join('', <$fh>);
    close($fh);
    return $txt;
}

my $base = "$TESTDIR/copy_files_and_dirs";
mkpath($base);

my @origs;
foreach my $fn (qw(/my/file /my/dir/file1 /my/dir/file2)) {
    my $dest = "$base/orig/$fn";
    mkfile($dest);
    push(@origs, $dest);
}

my $prefix = "$base/prefix";
# one file and one directory
ok($cmp->_copy_files_and_dirs($prefix, "$base/orig/my/file", "$base/orig/my/dir"),
   "copied file and dir $base/orig/my/file $base/orig/my/dir");

foreach my $fn (@origs) {
    my $copy = "$prefix/$fn";
    ok(-f $copy, "Found copy $copy of orig file $fn");
}

ok(! $cmp->_copy_files_and_dirs($prefix, "$base/orig/not/my/file"),
   "copy_files_and_dirs returns can't copy non-existing file/dir");

# no cleanup for debugging purposes
#rmtree($base);


=item intenal only __set_active_noaction_prefix and _prefix_noaction_prefix

=cut

my $testprefix = '/woohooo/test/noaction/prefix';

$cmp->__set_active_noaction_prefix($testprefix);
is(NCM::Component::spma::yum::_prefix_noaction_prefix("/myfile"), "$testprefix/myfile",
   "_prefix_noaction_prefix picks up new active noaction prefix", );

# reset
$cmp->__set_active_noaction_prefix('');

=item _match_noaction_tempdir / __match_template_dir

=cut

my $oktemplates = {
    "/abc/test-1234/hello" => "/abc/test-XXXX",
};

foreach my $test (sort keys %$oktemplates) {
    my $tmpl = $oktemplates->{$test};
    ok($cmp->__match_template_dir($test, $tmpl),
       "$test matches template $tmpl");
}

my $notoktemplates = {
    "/abc/test-123/hello" => "/abc/test-XXXX", # missing templated X
    "/abc/test-1234" => "/abc/test-XXXX", # not in subdir
    "/prefix/abc/test-1234/hello" => "/abc/test-XXXX", # does not start with
};

foreach my $test (sort keys %$notoktemplates) {
    my $tmpl = $notoktemplates->{$test};
    ok(! $cmp->__match_template_dir($test, $tmpl),
       "$test does not match template $tmpl");
}

# simple tests of constant template
ok($cmp->_match_noaction_tempdir("/tmp/spma-noaction-abcde/etc/yum.conf"),
    "File matches noaction tempdir template");

ok(!$cmp->_match_noaction_tempdir("/etc/yum.conf"),
    "File does not match noaction tempdir template");

=item noaction_prefix

=cut

is($cmp->noaction_prefix(0), '',
   "noaction_prefix with noaction=false returns empty string");

# can't mock / redefine NOACTION_TEMPDIR_TEMPLATE because it's already inlined in the subs
# would need a constants module or something like that

# lets mock tempdir usage instead
$mock->mock('tempdir', sub { return tempdir($MOCKED_TEMPLATE); });

# this code should be identical to orig method, except for the template
$mock->mock('_match_noaction_tempdir', sub {
    my ($self, $name) = @_;
    return $self->__match_template_dir($name, $MOCKED_TEMPLATE);
            });


my $tmppath = $cmp->noaction_prefix(1, "$base/orig/my/file", "$base/orig/my/dir");
ok($cmp->_match_noaction_tempdir($tmppath),
   "noaction_prefix generated tmppath matches (mocked) noaction tempdir");

foreach my $fn (@origs) {
    my $copy = "$tmppath/$fn";
    ok(-f $copy, "Found copy $copy of orig file $fn in noaction prefix");
}

# test chmod 0700
my $mode = (stat($tmppath))[2];
is($mode & 07777, 0700, "tmppath mode 0700");

# test failure mode
$error = '';
ok(! defined($cmp->noaction_prefix(1, "$base/orig/my/file", "$base/orig/my/dirtypo")),
   "noaction_prefix returns undef in case of problem with copying");
like($error, qr{^Can't copy non-existing},
     "expected error message for non-existing directory");

=item _override_noaction_fh

=cut


my $fh;

# Test FileWriter
my $notokfn = "$TESTDIR/test1";
ok(! $cmp->_match_noaction_tempdir($notokfn), "$notokfn does not match noaction tempdir");
$fh = CAF::FileWriter->new($notokfn);
ok(*$fh->{options}->{noaction}, "NoAction set on filewriter instance");

$error = '';
ok(! $cmp->_override_noaction_fh($fh),
   "nothing changed (wrong prefix)");

# it's normal the expected template is inlined constant, not the mocked one
like($error, qr{Not going to override noaction on file \S+/target/test/test1 \(expected template /tmp/spma-noaction-XXXXX\). Please report this issue to the developers, as this is most likely a bug in the code.},
     "expected error message for wrong prefix");

ok(*$fh->{options}->{noaction}, "NoAction still set on filewriter instance");

$fh->close();

#
my $okfn = "$TESTDIR/spma-noaction-abcde/test1";
ok($cmp->_match_noaction_tempdir($okfn), "$okfn matches noaction tempdir");
$fh = CAF::FileWriter->new($okfn);
ok(*$fh->{options}->{noaction}, "NoAction set on filewriter instance");

$error = '';
ok($cmp->_override_noaction_fh($fh),
   "allowed prefix to override noaction");

# it's normal the expected template is inlined constant, not the mocked one
is($error, '', "no error message for correct prefix");

ok(! *$fh->{options}->{noaction}, "NoAction disabled on filewriter instance");

$fh->cancel();
$fh->close();

# disable global NoAction
$NCM::Component::spma::yum::NoAction = 0;

$okfn .= "2";
ok($cmp->_match_noaction_tempdir($okfn), "$okfn matches noaction tempdir");

$fh = CAF::FileWriter->new("$okfn");

# becasue of CAF::Object::NoAction, does not follow the global one.
ok(*$fh->{options}->{noaction}, "NoAction set on filewriter instance");

$error = '';
ok(! $cmp->_override_noaction_fh($fh),
   "allowed prefix to override noaction, but NoAction is not set");

is($error, '', "no error message for no NoAction");

ok(*$fh->{options}->{noaction},
   "NoAction unchanged on filewriter instance with global NoAction disabled and matching prefix");

$fh->close();

# restore global NoAction
$NCM::Component::spma::yum::NoAction = 1;

=item cleanup_old_repos

=cut

my $repodir = "/etc/yum.repos.d/";
ok(! $cmp->_match_noaction_tempdir($repodir),
   "$repodir does not match noaction tempdir");
$error = '';
ok(! $cmp->cleanup_old_repos($repodir, undef, 1),
   "cleanup_old_repos fails with repodir that does not match noaction tempdir");
like($error, qr{Not going to going to cleanup repository files with NoAction with unexpected repository directory},
     "cleanup_old_repos failed with expected error message");

$repodir = "$TESTDIR/spma-noaction-abcde/etc/yum.repos.d/";
ok($cmp->_match_noaction_tempdir($repodir),
   "$repodir matches noaction tempdir");
$error = '';
ok($cmp->cleanup_old_repos($repodir, undef, 1),
   "cleanup_old_repos ok (due to userpkgs) with matching repodir and NoAction");
is($error, '', "cleanup_old_repos no errors with mocked opendir and matching reposdir");

# disable global NoAction
$NCM::Component::spma::yum::NoAction = 0;

$repodir = "/etc/yum.repos.d/";
ok(! $cmp->_match_noaction_tempdir($repodir),
   "$repodir does not match noaction tempdir");
$error = '';
ok($cmp->cleanup_old_repos($repodir, undef, 1),
   "cleanup_old_repos ok with repodir that does not match noaction tempdir (but due to userpkgs) with NoAction disabled");
is($error, '', "cleanup_old_repos no error with userpkgs and non-matching reposdir with NoAction disabled");

# restore global NoAction
$NCM::Component::spma::yum::NoAction = 1;


=item yum.conf points to tmppath

=cut

$cmp->configure_yum("$tmppath/etc/yum.conf", 1, "$tmppath/etc/yum/pluginconf.d", ["$tmppath/etc/yum.repos.d"]);

my $generatedconf = <<"EOF";

clean_requirements_on_remove=1

obsoletes=1

pluginconfpath=$tmppath/etc/yum/pluginconf.d

reposdir=$tmppath/etc/yum.repos.d
EOF

is(readfile("$tmppath/etc/yum.conf"), $generatedconf, "correctly generated text");

=item commands use new yum.conf

=cut

is_deeply(NCM::Component::spma::yum::_set_yum_config(['yum','arg1']),
          ['yum','-c',"$tmppath/etc/yum.conf",'arg1'],
          "temporary yum config correctly inserted");

=item Configure

=cut

my $yumbase = "$TESTDIR/configure_noaction";
mkfile("$yumbase/etc/yum.conf");
mkfile("$yumbase/etc/yum.repos.d/old.repo");
# not a valid config, but enough to test redefinition
mkfile("$yumbase/etc/yum/pluginconf.d/versionlock.conf", "locklist=/etc/yum/pluginconf.d/versionlock.list\n");
# unmanaged plugin, should be still there after copying
mkfile("$yumbase/etc/yum/pluginconf.d/unmanaged.conf");

# we need to mock a few things
# insert yumbase prefix to find source files,
# but will also put the files in $MOCKED_TEMPLATE/$yumbase, not $MOCKED_TEMPLATE/etc
$mock->mock('_copy_files_and_dirs', sub {
    my ($self, $prefix, @data) = @_;
    my $res = $mock->original('_copy_files_and_dirs')->($self, $prefix, map {"$yumbase/$_"} @data);
    diag "mocked _copy_files_and_dirs yumbase $yumbase res ".(defined $res ? $res : '<undef>');
    return $res;
            });

$mock->mock('noaction_prefix', sub {
    my ($self, $noaction, @data) = @_;
    my $tmppath = $mock->original('noaction_prefix')->($self, $noaction, @data);
    my $newtmppath = "$tmppath/$yumbase";
    diag "mocked noaction_prefix: noaction $noaction orig tmppath $tmppath new $newtmppath";
    $self->__set_active_noaction_prefix($newtmppath);
    return $newtmppath
            });

# let update fail; will also prevent cleanup to help debugging
$mock->mock('update_pkgs_retry', 0);

my $cfg = get_config_for_profile("noaction");

$error = '';
$cmp->Configure($cfg);

# get tmppath from the yum.conf
my $tmpycfg = NCM::Component::spma::yum::_set_yum_config(['yum'])->[2];
my $tmpetc = dirname($tmpycfg);
ok($cmp->_match_noaction_tempdir($tmpetc),
   "copied /etc that has yum.conf is a noaction tempdir $tmpetc");
ok(-d $tmpetc, "copied /etc $tmpetc is an actual directory");
is($error, '', 'No errors raised during configure');

# test removal of old.repo
ok(! -f "$tmpetc/yum.repos.d/old.repo", "old.repo is cleaned up");
# check if pkgs files and repo exist
ok(-f "$tmpetc/yum.repos.d/sl620_x86_64.repo", "repo file sl620_x86_64.repo created");
ok(-f "$tmpetc/yum.repos.d/sl620_x86_64.pkgs", "pkgs file sl620_x86_64.pkgs created");

# check if repo files include pkgs from tempdir
my $pattern = "^include=$tmpetc/yum.repos.d/sl620_x86_64.pkgs\$";
like(readfile("$tmpetc/yum.repos.d/sl620_x86_64.repo"), qr{$pattern}m,
     "pkgs file from noaction tempdir is included  in repo file");

$pattern = "^reposdir=$tmpetc/yum.repos.d\$";
like(readfile("$tmpetc/yum.conf"), qr{$pattern}m,
     "yum.conf reposdir from noaction tempdir is used");

$pattern = "^pluginconfpath=$tmpetc/yum/pluginconf.d\$";
like(readfile("$tmpetc/yum.conf"), qr{$pattern}m,
     "yum.conf pluginconfdir from noaction tempdir is used");

$pattern = "^locklist=$tmpetc/yum/pluginconf.d/versionlock.list\$";
like(readfile("$tmpetc/yum/pluginconf.d/versionlock.conf"), qr{$pattern}m,
     "versionlocklist from noaction tempdir is used");

ok(-f "$tmpetc/yum/pluginconf.d/priorities.conf",
   "pluginconf priorities defined in noaction tempdir");

ok(-f "$tmpetc/yum/pluginconf.d/fastestmirror.conf",
   "pluginconf fastestmirror defined in noaction tempdir");

ok(-f "$tmpetc/yum/pluginconf.d/unmanaged.conf",
   "unmanaged plgin conf found (copy was succesful)");

=pod

=back

=cut

done_testing();
