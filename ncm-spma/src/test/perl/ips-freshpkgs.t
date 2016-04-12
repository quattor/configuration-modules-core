# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::get_fresh_pkgs> method.  This method gets the set of
packages that would be installed in a fresh image.

=head1 TESTS

The test sets up a temporary directory to use as an image, sets up dummy
command outputs and then verifies the returned package set.

=cut

use strict;
use warnings;
use Test::More tests => 3;
use Test::Quattor;
use NCM::Component::spma::ips;
use Readonly;
use File::Path;

Readonly my $PKG_INSTALL_NV => join(" ",
                               @{NCM::Component::spma::ips::PKG_INSTALL_NV()});

Readonly my @wanted => ( 'local/perl/DB_File@latest',
                         'local/perl/GSSAPI@0.26',
                         'library/python-2/cherrypy',
                         'library/python-2/cherrypy-26'
                       );
Readonly my $pkg_output =>
" Startup: blah ...
Planning: blah blah ...
------------------------------------------------------------
           Packages to install:         4
           Mediators to change:         1
     Estimated space available: 208.74 GB
Estimated space to be consumed:   0.54 GB
            Services to change:         0
          Rebuild boot archive:        No

Changed mediators:
  mediator python:
           version: None -> 2.6 (vendor default)

Changed packages:
local
  local/perl/DB_File
    None -> 1.824,5.11-0:20130522T094739Z
  local/perl/GSSAPI
    None -> 0.26,5.11-0:20130522T101831Z
solaris
  library/python-2/cherrypy
    None -> 3.1.2,5.11-0.175.1.0.0.24.0:20120904T172651Z
  library/python-2/cherrypy-26
    None -> 3.1.2,5.11-0.175.1.0.0.24.0:20120904T172647Z
Services:
  disable_fmri:
    blah
  refresh_fmri:
    blah
  restart_fmri:
    blah";

my $cmp = NCM::Component::spma::ips->new("spma");

my $imagedir = NCM::Component::spma::ips::SPMA_IMAGEDIR . ".test.$$";
if (-d $imagedir) {
    rmtree($imagedir) or die "cannot remove $imagedir: $!";
}

my $pkg_cmd = $PKG_INSTALL_NV;
$pkg_cmd =~ s/<rootdir>/$imagedir/;
$pkg_cmd .= " " . join(" ", @wanted);
set_desired_output($pkg_cmd, $pkg_output);

my $fresh_set = $cmp->get_fresh_pkgs(\@wanted, $imagedir);
ok(defined(get_command($pkg_cmd)), "pkg install command was invoked");
is(@$fresh_set, @wanted, "Verify number of packages in fresh set");

my $pkgs_ok = 1;
for my $pkg (@wanted) {
    (my $name = $pkg) =~ s/@.*$//;
    $pkgs_ok = 0 unless $fresh_set->has($name);
}
ok($pkgs_ok, "Verify contents of fresh package set");
