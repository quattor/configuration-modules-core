# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the generate_sources method.  They will ensure that entries in
/etc/apt.lists.d are properly handled.

=cut

use strict;
use warnings;
use Test::Quattor;
use Test::More;
use NCM::Component::spma::apt;
use Readonly;
use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();

Readonly my $SOURCES_DIR => "/etc/apt/sources.list.d";
Readonly my $SOURCES_TEMPLATE => "apt/source.tt";
Readonly my $PROXY_HOST => "aproxy";
Readonly my $PROXY_PORT => 9876;
Readonly my $URL => "http://localhost.localdomain";

sub initialise_sources
{
    return [
        {
            name => "a_source",
            owner => 'localuser@localdomain',
            enabled => 1,
            protocols => [
                {
                    name => "http",
                    url => "$URL trusty main",
                },
                {
                    name => "http",
                    url => "$URL/another/path trusty main",
                },
            ],
            includepkgs => [qw(foo bar)],
            excludepkgs => [qw(baz quux)],
        }
    ];
}

my $sources = initialise_sources();

my $cmp = NCM::Component::spma::apt->new("spma");

=pod

=head1 TESTS

=head2 Creation of a valid source file

The information from the profile should be reflected in the
configuration files.

=cut

ok(defined($cmp->generate_sources($SOURCES_DIR, $sources, $SOURCES_TEMPLATE)), "Basic source correctly created");


my $name = $sources->[0]->{name};
my $fh = get_file("$SOURCES_DIR/$name.list");
ok(defined($fh), "Correct file opened");


=pod

=head2 Error handling

Failures in rendering a template are reported, and nothing is written
to disk.

=cut

remove_any("$SOURCES_DIR/$name.list");
is($cmp->generate_sources($SOURCES_DIR, $sources, "an invalid template name"), 0, "Invalid template name is detected");
is($cmp->{ERROR}, 1, "Errors on template rendering are reported");
$fh = get_file("$SOURCES_DIR/$name.list");
ok(!defined($fh), "No file could be opened, render failed");

done_testing();

=pod

=back

=cut
