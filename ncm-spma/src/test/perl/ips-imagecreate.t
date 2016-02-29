# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::image_create> method.  This method creates an image
suitable for dry-run package operations.

=head1 TESTS

The test sets up a temporary directory and dummy command outputs so that
the method can set-up publishers in the new image, and then proceeds
to verify the contents of the pkg-publisher.conf file.

=cut

use strict;
use warnings;
use Test::More tests => 4;
use Test::Quattor;
use NCM::Component::spma::ips;
use Readonly;
use File::Path;

Readonly my $PKG_PUBLISHER => join(" ",
                           @{NCM::Component::spma::ips::PKG_PUBLISHER()});
Readonly my $PKG_SET_PUBLISHER => join(" ",
                           @{NCM::Component::spma::ips::PKG_SET_PUBLISHER()});

Readonly my $publishers =>
"solaris true    false   true    origin  online  http://localhost/ips/s11-support-idrs/      -
solaris true    false   true    origin  online  http://localhost/ips/s11-support/   -
local   true    false   true    origin  online  http://localhost/ips/local/    -";

my $cmp = NCM::Component::spma::ips->new("spma");

my $imagedir = NCM::Component::spma::ips::SPMA_IMAGEDIR . ".test.$$";
if (-d $imagedir) {
    rmtree($imagedir) or die "cannot remove $imagedir: $!";
}

set_desired_output($PKG_PUBLISHER, $publishers);

$cmp->image_create($imagedir);
ok(defined(get_command($PKG_PUBLISHER)), "pkg publisher command was invoked");
my $pubfile = "$imagedir/pkg-publisher.conf";
ok(-f $pubfile, "pkg-publisher.conf file created");

my @set_publisher;
for (my @lst = split/\n/, $publishers) {
    my ($publisher, $sticky, $syspub, $enabled, $type,
            $status, $uri, $proxy) = split;
    my $cmd = $PKG_SET_PUBLISHER;
    $cmd =~ s/<rootdir>/$imagedir/;
    push @set_publisher, "$cmd -g $uri $publisher\n";
}

open(my $pubcfg, "<", "$imagedir/pkg-publisher.conf") or
                            die "cannot open $pubfile for reading: $!";
my @publines = <$pubcfg>;
close($pubcfg);
rmtree($imagedir) if -d $imagedir;

is(@publines, @set_publisher,
        "pkg-publisher.conf file has the correct number of entries");

my $i = 0;
my $cmds_ok = 1;
for my $cmd (@publines) {
    $cmds_ok = 0 if $cmd ne $set_publisher[$i];
    $i++;
}

ok($cmds_ok, "pkg-publisher.conf file has correct entries");
