use strict;
use warnings;

use Test::Quattor;
use Test::More;
use NCM::Component::spma::yum;
use CAF::Object;
use Test::Quattor::TextRender::Base;

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

my $caf_trd = mock_textrender();

my ($changes, $fh, $text);

my $cmp = NCM::Component::spma::yum->new("spma");

=pod

=head1 Test defaults

=cut

$changes = $cmp->configure_plugins();
is($changes, 2, "2 modified files when no plugins are passed");

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


=pod

=head1 Test settings

=cut

$changes = $cmp->configure_plugins({
    versionlock => {
        enabled => 0,
        locklist => '/somewhere/else',
    },
    fastestmirror => {
        enabled => 1,
    }
});
is($changes, 2, "2 modified files with 2 plugins passed");

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



done_testing();
