# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::load_installed_set> method.  This method returns a new
set of currently installed packages.

=head1 TESTS

The test sets up dummy output for the PKG_LIST command and
verifies the output of the method.

=cut

use strict;
use warnings;
use Test::More tests => 2;
use Test::Quattor;
use NCM::Component::spma::ips;
use Readonly;

Readonly my $PKG_LIST => join(" ", @{NCM::Component::spma::ips::PKG_LIST()});
Readonly my $pkg_list_subset =>
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
system/library/libpcap                            1.1.1-0.175.1.0.0.24.0     i--
system/library/math                               0.5.11-0.175.1.0.0.19.0    i--
system/library/openmp                             0.5.11-0.175.1.0.0.19.0    i--
system/library/platform                           0.5.11-0.175.1.0.0.24.2    i--
system/library/policykit                          0.5.11-0.175.1.0.0.24.2    i--
system/library/processor                          0.5.11-0.175.1.0.0.24.2    i--
system/library/security/gss                       0.5.11-0.175.1.0.0.24.2    i--
system/library/security/gss/diffie-hellman        0.5.11-0.175.1.0.0.24.2    i--
system/library/security/gss/spnego                0.5.11-0.175.1.0.0.24.2    i--
system/library/security/libgcrypt                 1.4.5-0.175.0.0.0.0.0      i--
system/library/security/libsasl                   0.5.11-0.175.1.0.0.24.2    i--
system/library/security/rpcsec                    0.5.11-0.175.1.0.0.24.2    i--
system/library/storage/libdiskmgt                 0.5.11-0.175.1.0.0.24.2    i--
system/library/storage/libfcoe                    0.5.11-0.175.1.0.0.24.2    i--
system/library/storage/scsi-plugins               0.5.11-0.175.1.0.0.24.2    i--
system/library/storage/snia-hbaapi                0.5.11-0.175.1.0.0.24.2    i--
system/library/storage/snia-ima                   0.5.11-0.175.1.0.0.24.2    i--
system/library/storage/snia-mpapi                 0.5.11-0.175.1.0.0.24.2    i--
system/library/storage/suri                       0.5.11-0.175.1.0.0.24.2    i--
system/library/storage/t11-sm-hba                 0.5.11-0.175.1.0.0.24.2    i--
system/library/usb/libusb                         0.5.11-0.175.1.0.0.24.0    i--
system/library/usb/libusbugen                     0.5.11-0.175.1.0.0.24.0    i--";

my $cmp = NCM::Component::spma::ips->new("spma");
set_desired_output($PKG_LIST, $pkg_list_subset);

my $installed_set = $cmp->load_installed_set();
ok(defined(get_command($PKG_LIST)), "pkg list command was invoked");

my %pkg_hash;
for my $line (split /\n/, $pkg_list_subset) {
    $line =~ s/ .*$//;
    $pkg_hash{$line} = 1;
}

my $hash_ok = 1;
for my $pkg (@$installed_set) {
    $hash_ok = 0 unless $pkg_hash{$pkg};
}

ok($hash_ok, "Package set loaded correctly");
