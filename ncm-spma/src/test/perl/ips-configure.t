# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<ips::Configure> method.

=head1 TESTS

The test sets up dummy output for the critical commands and sets up
a number of dummy runs, checking the exit status and that a number of
commands would have been executed as expected.

=cut

use strict;
use warnings;
use Test::More tests => 12;
use Test::Quattor qw(ips-core ips-run);
use NCM::Component::spma::ips;
use Readonly;

use constant CMP_TREE => "/software/components/spma";

Readonly my $BEADM_LIST => join(" ",
                                @{NCM::Component::spma::ips::BEADM_LIST()});
Readonly my $beadm_list =>
"11.1.10.5.0;3295f569-cb96-6095-fcc5-ea230deead53;;;1152157184;static;1383314046
after-postinstall;86da11ce-a5c0-c9a1-92c3-ffdc850b5824;;;53248;static;1353932413
11.1.12.5.0;4ce21b58-91ce-6748-caf9-f12279aa45ba;;;55820196864;static;1385592777
before-postinstall;40a3490d-12be-418f-9064-cc0a119228fb;;;417792;static;1353929579
test;41b89679-6a23-4aef-f4d6-d88cdf41c17d;;;18536510976;static;1353933808
test-backup-1;2170e922-e65b-678b-cc18-f97e536d4960;;;0;static;1354206957
solaris;92ea8774-d365-4c8e-e0ec-847092cb0869;NR;;1168384;static;1353928512";

Readonly my $PKG_LIST => join(" ", @{NCM::Component::spma::ips::PKG_LIST()});
Readonly my $pkg_list =>
"system/library                                    0.5.11-0.175.1.0.0.24.2   i--
system/library/boot-management                    0.5.11-0.175.1.0.0.24.2    i--
system/library/c++-runtime                        0.5.11-0.175.1.0.0.19.0    i--
system/library/c++/sunpro                         0.5.11-0.168               i-r
system/library/dbus                               1.2.28-0.175.1.0.0.24.2    i--
system/library/flex-runtime                       2.5.35-0.175.1.0.0.24.0    i--
system/library/fontconfig                         2.8.0-0.175.1.0.0.24.1317  i--
system/library/freetype-2                         2.4.9-0.175.1.0.0.24.1317  i--
system/library/gcc-3-runtime                      3.4.3-0.175.1.0.0.24.0     i--
system/library/gcc-45-runtime                     4.5.2-0.175.1.0.0.24.0     i--
system/library/iconv/unicode                      0.5.11-0.175.1.0.0.23.1134 i--
system/library/iconv/unicode-core                 0.5.11-0.175.1.0.0.23.1134 i--
system/library/iconv/utf-8                        0.5.11-0.175.1.0.0.23.1134 i--
system/library/install                            0.5.11-0.175.1.0.0.24.1736 i--
system/library/libdbus                            1.2.28-0.175.1.0.0.24.2    i--
system/library/libdbus-glib                       0.88-0.175.0.0.0.0.0       i--
system/library/libpcap                            1.1.1-0.175.1.0.0.24.0     i--";

Readonly my $PKG_AVOID => join(" ", @{NCM::Component::spma::ips::PKG_AVOID()});
Readonly my $SPMA_RUN_NOACTION => join(" ",
                            @{NCM::Component::spma::ips::SPMA_RUN_NOACTION()});
Readonly my $SPMA_RUN_EXECUTE => join(" ",
                            @{NCM::Component::spma::ips::SPMA_RUN_EXECUTE()});

sub get_files
{
    my ($config) = @_;
    my $t = $config->getElement(CMP_TREE)->getTree();
    my $cmdfile = $t->{cmdfile};
    my $flagfile = $t->{flagfile};
    $cmdfile =~ s/\$\$/$$/g;
    $flagfile =~ s/\$\$/$$/g;
    return ($cmdfile, $flagfile);
}

sub clean_up
{
    my ($cmdfile, $flagfile) = @_;
    remove_any($cmdfile);
    remove_any($flagfile);
}

my $cmp = NCM::Component::spma::ips->new("spma");
set_desired_output($BEADM_LIST, $beadm_list);   # list of BEs
set_desired_output($PKG_LIST, $pkg_list);       # list of installed packages

my $config = get_config_for_profile("ips-core");
my ($cmdfile, $flagfile) = get_files($config);
is($cmp->Configure($config), 1, "Core configuration succeeds");
ok(defined(get_command($BEADM_LIST)), "beadm list command was invoked");
ok(defined(get_command($PKG_LIST)), "pkg list command was invoked");
ok(defined(get_command($SPMA_RUN_NOACTION)), "spma-run --noaction was invoked");

#
# Retry with a pkg avoid list
#
set_desired_output($PKG_AVOID, "system/network/ppp (group dependency of 'group/system/solaris-large-server')");
is($cmp->Configure($config), 1, "Configuration succeeds with pkg avoid");
ok(defined(get_command($PKG_AVOID)), "pkg avoid command was invoked");
ok(defined(get_file($flagfile)), "Flag file $flagfile should exist");

clean_up($cmdfile, $flagfile);

#
# Retry with run set to 'yes'
#
$config = get_config_for_profile("ips-run");
($cmdfile, $flagfile) = get_files($config);
is($cmp->Configure($config), 1, "Run configuration succeeds");
ok(defined(get_command($BEADM_LIST)), "beadm list command was invoked");
ok(defined(get_command($PKG_LIST)), "pkg list command was invoked");
ok(defined(get_command($SPMA_RUN_EXECUTE)), "spma-run --execute was invoked");
ok(!defined(get_file($flagfile)), "Flag file $flagfile should not exist");

clean_up($cmdfile, $flagfile);
