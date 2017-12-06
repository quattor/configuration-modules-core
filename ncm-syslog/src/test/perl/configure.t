use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Quattor qw(basic);
use NCM::Component::syslog;
use CAF::Object;

my $cmp = NCM::Component::syslog->new('syslog');

my $cfg = get_config_for_profile('basic');

my $tree = $cfg->getTree($cmp->prefix);

=head1 edit

=cut

my $edit_fn = '/dummy/edit';

my $edit_orig = <<EOF;
# comment
directive two # ncm-syslog
random stuff
directive three # ncm-syslog
*.error super*powers
*.* other action
EOF


my $edit_new = <<EOF;
directive one                            # ncm-syslog
directive three                          # ncm-syslog
# comment
random stuff
*.* super*powers
*.* other action
user.crit\tawesome
mail.debug\tawesome
uucp,news.crit\t/var/log/spooler
EOF

set_file_contents($edit_fn, $edit_orig);
is($cmp->edit($tree, $edit_fn), 1, "edit returns file changed");
my $efh = get_file($edit_fn);
is("$efh", $edit_new, "config file edited");

=head2 render

=cut

my $render_fn = '/dummy/render';

my $render_orig = <<EOF;
# comment
directive two # ncm-syslog
random stuff
directive three # ncm-syslog
*.error super*powers
*.* other action
EOF

my $render_new = <<EOF;
directive one                            # ncm-syslog
directive three                          # ncm-syslog

# a comment
*.*\tsuper*powers
\tmooore

# already wrapped
user.crit;mail.debug\tawesome
uucp,news.crit\t/var/log/spooler
EOF

set_file_contents($render_fn, $render_orig);
is($cmp->render($tree, $render_fn), 1, "render returns file changed");
my $rfh = get_file($render_fn);
is("$rfh", $render_new, "config file rendered");

=head1 sysconfig

=cut

my $sysconfig_fn = '/dummy/sysconfig';

my $sysconfig_orig = <<EOF;
A="b"
SYSLOGD_OPTIONS="super super"
Z="y"
EOF

my $sysconfig_new = <<EOF;
A="b"
SYSLOGD_OPTIONS="a b c"
Z="y"
KLOGD_OPTIONS="d e f"
EOF

set_file_contents($sysconfig_fn, $sysconfig_orig);
is($cmp->sysconfig($tree, $sysconfig_fn), 1, "sysconfig returns file changed");
my $sfh = get_file($sysconfig_fn);
is("$sfh", $sysconfig_new, "sysconfig file edited");


=head1 Configure

=cut


# no initial files
$cmp->Configure($cfg);

my $sysfh = get_file('/etc/sysconfig/rsyslog');
is("$sysfh", "SYSLOGD_OPTIONS=\"a b c\"\nKLOGD_OPTIONS=\"d e f\"\n", "expected generated sysconfig");

my $cfgfh = get_file('/etc/rsyslog.conf');
is("$cfgfh", $render_new, "expected generated rsyslog config (via fullcontrol=1/render)");

ok(get_command('service rsyslog restart'), 'restart service rsyslog');

done_testing();
