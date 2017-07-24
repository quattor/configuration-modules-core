use strict;
use warnings;

use Test::Quattor;
use Test::More;
use NCM::Component::spma::yum;
use CAF::Object;
use Test::Quattor::TextRender::Base;

use Readonly;
Readonly my $YUM_PLUGIN_DIR => "/etc/yum/pluginconf.d";

my $caf_trd = mock_textrender();

my ($changes, $fh, $text);

my $cmp = NCM::Component::spma::yum->new("spma");

=pod

=head1 Test defaults

=cut

$changes = $cmp->configure_plugins($YUM_PLUGIN_DIR);
is($changes, 3, "3 modified files when no plugins are passed");

$fh = get_file('/etc/yum/pluginconf.d/versionlock.conf');
isa_ok($fh, 'CAF::FileWriter', '/etc/yum/pluginconf.d/versionlock.conf is a CAF::FileWriter');
$text = "$fh";
$text =~ s/\s//g;
is($text, '[main]enabled=1locklist=/etc/yum/pluginconf.d/versionlock.list', "Expected text for default versionlock enabled");

$fh = get_file('/etc/yum/pluginconf.d/fastestmirror.conf');
isa_ok($fh, 'CAF::FileWriter', '/etc/yum/pluginconf.d/fastestmirror.conf is a CAF::FileWriter');
$text = "$fh";
$text =~ s/\s//g;
is($text, '[main]enabled=0', "Expected text for default fastestmirror disabled");

$fh = get_file('/etc/yum/pluginconf.d/priorities.conf');
isa_ok($fh, 'CAF::FileWriter', '/etc/yum/pluginconf.d/priorities.conf is a CAF::FileWriter');
$text = "$fh";
$text =~ s/\s//g;
is($text, '[main]enabled=1', "Expected text for default priorities enabled");


=pod

=head1 Test settings

=cut

$changes = $cmp->configure_plugins($YUM_PLUGIN_DIR, {
    versionlock => {
        enabled => 0,
        locklist => '/somewhere/else',
    },
    fastestmirror => {
        enabled => 1,
    },
    priorities => {
        enabled => 0,
    }
});
is($changes, 3, "3 modified files with 2 plugins passed");

$fh = get_file('/etc/yum/pluginconf.d/versionlock.conf');
isa_ok($fh, 'CAF::FileWriter', '/etc/yum/pluginconf.d/versionlock.conf is a CAF::FileWriter');
$text = "$fh";
$text =~ s/\s//g;
is($text, '[main]enabled=0locklist=/etc/yum/pluginconf.d/versionlock.list',
   "Expected text for versionlock disabled/forced location of locklist");

$fh = get_file('/etc/yum/pluginconf.d/fastestmirror.conf');
isa_ok($fh, 'CAF::FileWriter', '/etc/yum/pluginconf.d/fastestmirror.conf is a CAF::FileWriter');
$text = "$fh";
$text =~ s/\s//g;
is($text, '[main]enabled=1',
   "Expected text for fastestmirror enabled");

$fh = get_file('/etc/yum/pluginconf.d/priorities.conf');
isa_ok($fh, 'CAF::FileWriter', '/etc/yum/pluginconf.d/priorities.conf is a CAF::FileWriter');
$text = "$fh";
$text =~ s/\s//g;
is($text, '[main]enabled=0', "Expected text for priorities disabled");


done_testing();
