#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;
use Test::NoWarnings;
use Test::Quattor;
use NCM::Component::named;
use Readonly;
use CAF::Object;
Test::NoWarnings::clear_warnings();

my $NAMED_CONFIG_FILE = $NCM::Component::named::NAMED_CONFIG_FILE;
my $NAMED_SYSCONFIG_FILE = $NCM::Component::named::NAMED_SYSCONFIG_FILE;
my $RESOLVER_CONF_FILE = $NCM::Component::named::RESOLVER_CONF_FILE;


# This is the content of the default file on SL6 (with single quote removed in the text)
use constant TEST_SYSCONFIG_HEADER => '# BIND named process options
# ~~~~~~~~~~~~~~~~~~~~~~~~~~
# Currently, you can use the following options:
#
# ROOTDIR="/var/named/chroot"  --  will run named in a chroot environment.
#                            you must set up the chroot environment
#                            (install the bind-chroot package) before
#                            doing this.
#       NOTE:
#         Those directories are automatically mounted to chroot if they are
#         empty in the ROOTDIR directory. It will simplify maintenance of your
#         chroot environment.
#          - /var/named
#          - /etc/pki/dnssec-keys
#          - /etc/named
#          - /usr/lib64/bind or /usr/lib/bind (architecture dependent)
#
#         Those files are mounted as well if target file does not exist in
#         chroot.
#          - /etc/named.conf
#          - /etc/rndc.conf
#          - /etc/rndc.key
#          - /etc/named.rfc1912.zones
#          - /etc/named.dnssec.keys
#          - /etc/named.iscdlv.key
#
#       Do not forget to add "$AddUnixListenSocket /var/named/chroot/dev/log"
#       line to your /etc/rsyslog.conf file. Otherwise your logging becomes
#       broken when rsyslogd daemon is restarted (due update, for example).
#
# OPTIONS="whatever"     --  These additional options will be passed to named
#                            at startup. Do not add -t here, use ROOTDIR instead.
#
# KEYTAB_FILE="/dir/file"    --  Specify named service keytab file (for GSS-TSIG)
#
# DISABLE_ZONE_CHECKING  -- By default, initscript calls named-checkzone
#                           utility for every zone to ensure all zones are
#                           valid before named starts. If you set this option
#                           to yes then initscript does not perform those
#                           checks.
';

use constant TEST_ROOTDIR_VALUE => '/var/named/test';
use constant TEST_SYSCONFIG_UNCOMMENTED_LINE => 'ROOTDIR='.TEST_ROOTDIR_VALUE."\n";
use constant TEST_SYSCONFIG_UNCOMMENTED_LINE_QUOTED => "ROOTDIR='".TEST_ROOTDIR_VALUE."'\n";
use constant TEST_SYSCONFIG_UNCOMMENTED_LINE_2QUOTED => 'ROOTDIR="'.TEST_ROOTDIR_VALUE.'"'."\n";

use constant TEST_SYSCONFIG_COMMENTED_LINE => '#ROOTDIR="/var/named/commented"'."\n";


$CAF::Object::NoAction = 1;

=pod

=head1 SYNOPSIS

This is a test suite for ncm-named getNamedRootDir() function.

=cut

my $cmp = NCM::Component::named->new('named');

set_file_contents($NAMED_SYSCONFIG_FILE, TEST_SYSCONFIG_UNCOMMENTED_LINE);
my $named_root_dir = $cmp->getNamedRootDir();
is($named_root_dir,TEST_ROOTDIR_VALUE,"single uncommented line: named root directory has expected value");

set_file_contents($NAMED_SYSCONFIG_FILE, TEST_SYSCONFIG_UNCOMMENTED_LINE_QUOTED);
$named_root_dir = $cmp->getNamedRootDir();
is($named_root_dir,TEST_ROOTDIR_VALUE,"single uncommented line with quotes: named root directory has expected value");

set_file_contents($NAMED_SYSCONFIG_FILE, TEST_SYSCONFIG_UNCOMMENTED_LINE_2QUOTED);
$named_root_dir = $cmp->getNamedRootDir();
is($named_root_dir,TEST_ROOTDIR_VALUE,"single uncommented line with double quotes: named root directory has expected value");

set_file_contents($NAMED_SYSCONFIG_FILE, TEST_SYSCONFIG_HEADER.TEST_SYSCONFIG_UNCOMMENTED_LINE_2QUOTED);
$named_root_dir = $cmp->getNamedRootDir();
is($named_root_dir,TEST_ROOTDIR_VALUE,"complete file with uncommented value: named root directory has expected value");

set_file_contents($NAMED_SYSCONFIG_FILE, TEST_SYSCONFIG_COMMENTED_LINE);
$named_root_dir = $cmp->getNamedRootDir();
is($named_root_dir,'',"single commented line: named root directory has expected value");

set_file_contents($NAMED_SYSCONFIG_FILE, TEST_SYSCONFIG_HEADER.TEST_SYSCONFIG_COMMENTED_LINE);
$named_root_dir = $cmp->getNamedRootDir();
is($named_root_dir,'',"complete file with commented value: named root directory has expected value");

set_file_contents($NAMED_SYSCONFIG_FILE, TEST_SYSCONFIG_HEADER.TEST_SYSCONFIG_UNCOMMENTED_LINE.TEST_SYSCONFIG_COMMENTED_LINE);
$named_root_dir = $cmp->getNamedRootDir();
is($named_root_dir,TEST_ROOTDIR_VALUE,"complete file with commented value: named root directory has expected value");

set_file_contents($NAMED_SYSCONFIG_FILE, TEST_SYSCONFIG_HEADER.TEST_SYSCONFIG_COMMENTED_LINE.TEST_SYSCONFIG_UNCOMMENTED_LINE);
$named_root_dir = $cmp->getNamedRootDir();
is($named_root_dir,TEST_ROOTDIR_VALUE,"complete file with commented value: named root directory has expected value");

Test::NoWarnings::had_no_warnings();
