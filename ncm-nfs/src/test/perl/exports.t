use strict;
use warnings;

use Test::More;
use Test::Quattor qw(exports noexports);

use Test::Quattor::RegexpTest;

use NCM::Component::nfs;

use CAF::Object;
$CAF::Object::NoAction = 1;

set_caf_file_close_diff(1);

my $cmp = NCM::Component::nfs->new('nfs');

my $cfg = get_config_for_profile('noexports');
my $tree = $cfg->getTree($cmp->prefix());
diag explain $tree;
is($cmp->exports($tree), 1, "exports file changed (noexports)");
my $fh = get_file('/etc/exports');

diag "noexports ", "$fh";
Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/regexps/noexports',
    text => "$fh",
    )->test();

$cfg = get_config_for_profile('exports');
$tree = $cfg->getTree($cmp->prefix());
diag explain $tree;
is($cmp->exports($tree), 1, "exports file changed (exports)");
$fh = get_file('/etc/exports');

diag "exports ", "$fh";
Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/regexps/exports',
    text => "$fh",
    )->test();


done_testing();
