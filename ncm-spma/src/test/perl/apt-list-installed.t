# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

More tests for the C<installed_pkgs> method. This time we test that
all the debs are printed in a format that APT will understand.

=head1 TESTS

These tests will run only if the dpkg binary is present.  They consist
on retrieving the set of all installed packages and ensure there are
no surprising strings among them.

=cut

use strict;
use warnings;
use Test::Quattor;
use Test::More;
use NCM::Component::spma::apt;
use Readonly;
use Set::Scalar;

my $cmp = NCM::Component::spma::apt->new("spma");

Readonly my $QUERYCMD => '/usr/bin/dpkg-query -W -f=${db:Status-Abbrev};${Package}\n';

set_desired_output($QUERYCMD, 'ii ;accountsservice
ii ;curl
ii ;fuse
ii ;gvfs-libs
ii ;init-system-helpers
ii ;insserv
ii ;insserv
rc ;gnuplot-qt
ii ;libc6-dev
ii ;libcap2-bin
ii ;libconfig-file-perl
ii ;libcryptsetup4
ii ;libdns100
rc ;libepoxy0
ii ;libgnutls26
ii ;libgtk2.0-0
ii ;libieee1284-3
ii ;liblua5.2-0
ii ;libnetty-java
ii ;libpixman-1-0
ii ;libplexus-sec-dispatcher-java
ii ;libsctp1
ii ;libsisu-guice-java
ii ;libunistring0
ii ;libx11-6
ii ;linux-headers-3.13.0-108
ii ;linux-headers-3.13.0-109-generic
ii ;mime-support
ii ;ncurses-base
ii ;ncurses-base
ii ;perl-modules
ii ;pppconfig
ii ;python2.7
ii ;vim-tiny
rc ;xserver-xorg-video-intel
');

my $pkgs = $cmp->get_installed_pkgs();

ok(get_command($QUERYCMD), 'Correct command called');

isa_ok($pkgs, "Set::Scalar", "installed_pkgs()");

is($pkgs, Set::Scalar->new(qw(
    accountsservice
    curl
    fuse
    gvfs-libs
    init-system-helpers
    insserv
    libc6-dev
    libcap2-bin
    libconfig-file-perl
    libcryptsetup4
    libdns100
    libgnutls26
    libgtk2.0-0
    libieee1284-3
    liblua5.2-0
    libnetty-java
    libpixman-1-0
    libplexus-sec-dispatcher-java
    libsctp1
    libsisu-guice-java
    libunistring0
    libx11-6
    linux-headers-3.13.0-108
    linux-headers-3.13.0-109-generic
    mime-support
    ncurses-base
    perl-modules
    pppconfig
    python2.7
    vim-tiny
)), "Package set returned as expected");

done_testing();
