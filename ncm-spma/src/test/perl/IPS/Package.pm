##############################################################################
#
# Copyright (C) 2013 Contributor
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
##############################################################################
#
# IPS::Package module
# Author: Mark R. Bannister
#
# Routines for manipulating Solaris IPS package information.
#
##############################################################################
package IPS::Package;

use strict;
use warnings;

use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(pkg_add_lookup pkg_lookup pkg_lookup_installed fmri_match);

=head1 NAME

IPS::Package - IPS package name support module

=head1 SYNOPSIS

  use IPS;

  IPS::Package::pkg_add_lookup("pkg:/shell/bash");
  @output = IPS::Package::pkg_lookup("bash");
  @output = IPS::Package::pkg_lookup_re("^idr[0-9]");
  print "match\n" if IPS::Package::fmri_match(
                        "pkg:/shell/bash", "shell/bash");

=head1 DESCRIPTION

Supporting routines used by B<pkgtree> to find packages based on
partial and full FMRIs.

This module handles the package name component of an FMRI.  Use
B<IPS::Version> for routines that work on the version number.

=over 5

=item B<pkg_add_lookup>(I<pkg_fmri>, [I<installed>], [I<pkg_map>])

Adds full package name to lookup hash as well as its various shortened forms.
The lookup hash is used by subsequent routines in this module.  Note that
the FMRI should not actually contain a version component.

The I<installed> flag can be 1 to indicate that the package is installed,
or 0 to indicate that it is not installed.  This flag is used by
B<pkg_lookup_installed>.  If omitted, the default is 1.

If I<pkg_map> is not provided then the module global hash B<IPS::pkg_map>
will be used instead.

=cut

sub pkg_add_lookup
{
    my ($pkg_fmri, $installed, $pkg_map) = @_;
    $pkg_map ||= \%IPS::pkg_map;

    (my $name = $pkg_fmri) =~ s=^pkg://[^/]*/==;   # strip off publisher
    $pkg_map->{$name}->{$pkg_fmri} = $installed
        if ! $pkg_map->{$name}->{$pkg_fmri};

    while ($name =~ /\//) {
        $name =~ s=^[^/]*/==;        # strip off leading component
        $pkg_map->{$name}->{$pkg_fmri} = $installed
            if $name and ! $pkg_map->{$name}->{$pkg_fmri};
    }
}

=item B<pkg_lookup>(I<pkg_fmri>, [I<pkg_map>])

Looks up full or partial package name in the package map, returning
an array of full matching packages (if possible).

If I<pkg_map> is not provided then the module global hash B<IPS::pkg_map>
will be used instead.

=cut

sub pkg_lookup
{
    my ($pkg_fmri, $pkg_map) = @_;
    $pkg_map ||= \%IPS::pkg_map;

    if (substr($pkg_fmri, 0, 6) eq 'pkg://') {
        #
        # This is already a full FMRI, as it has a publisher component
        #
        return $pkg_fmri;
    }

    #
    # Remove pkg:/ or single / prefix
    #
    (my $name = $pkg_fmri) =~ s=^(pkg:)?/==;

    my $pkg_hash = $pkg_map->{$name};
    return "pkg:/$name" if ! $pkg_hash;
    return keys %$pkg_hash;
}

=item B<pkg_lookup_installed>(I<pkg_fmri>, [I<pkg_map>])

Same as B<pkg_lookup> except only works on packages marked as installed.
Knowledge of whether a package is installed or not depends on the value
of the I<installed> flag previously passed to B<pkg_add_lookup>.

=cut

sub pkg_lookup_installed
{
    my ($pkg_fmri, $pkg_map) = @_;
    $pkg_map ||= \%IPS::pkg_map;

    #
    # Strip off publisher, remove pkg:/ or single / prefix
    #
    (my $name = $pkg_fmri) =~ s,^(pkg://[^/]*/|pkg:/|/),,;

    my $pkg_hash = $pkg_map->{$name};
    return if ! $pkg_hash;

    my @pkg_list;
    for my $fmri (keys %$pkg_hash) {
        push @pkg_list, $fmri if $pkg_hash->{$fmri};
    }
    return @pkg_list;
}

=item B<pkg_lookup_re>(I<pkg_re>, [I<pkg_map>])

Looks up package name with a regular expression in the package map, returning
an array of full matching packages (if possible).

If I<pkg_map> is not provided then the module global hash B<IPS::pkg_map>
will be used instead.

=cut

sub pkg_lookup_re
{
    my ($pkg_re, $pkg_map) = @_;
    $pkg_map ||= \%IPS::pkg_map;

    my @results;
    for my $name (keys %$pkg_map) {
        for my $fmri (keys %{$pkg_map->{$name}}) {
            push @results, $fmri if $fmri =~ $pkg_re or $name =~ $pkg_re;
        }
    }
    return @results;
}

=item B<pkg_lookup_installed_re>(I<pkg_re>, [I<pkg_map>])

Same as B<pkg_lookup_re> except only works on packages marked as installed.
Knowledge of whether a package is installed or not depends on the value
of the I<installed> flag previously passed to B<pkg_add_lookup>.

=cut

sub pkg_lookup_installed_re
{
    my ($pkg_re, $pkg_map) = @_;
    $pkg_map ||= \%IPS::pkg_map;

    my @results;
    for my $name (keys %$pkg_map) {
        for my $fmri (keys %{$pkg_map->{$name}}) {
            push @results, $fmri if $pkg_map->{$name}->{$fmri} and \
                                    ($fmri =~ $pkg_re or $name =~ $pkg_re);
        }
    }
    return @results;
}

=item B<fmri_match>(I<fmri1>, I<fmri2>)

Checks two package names, and returns 1 if they match.
Supports full and partial matching.

=cut

sub fmri_match
{
    my ($fmri1, $fmri2) = @_;

    #
    # If both FMRIs have a publisher name, we can include the publisher
    # name in the comparison, otherwise we can't
    #
    if (!fmri_common(\$fmri1, \$fmri2, '^pkg://')) {
        #
        # FMRIs may optionally start with pkg:/ but we should ignore
        # leading pkg: or leading / in our comparisons if they are 
        # not found in both FMRIs (unless publisher is included which
        # was tested for above)
        #
        fmri_common(\$fmri1, \$fmri2, '^pkg:');
        fmri_common(\$fmri1, \$fmri2, '^/');
    }

    my @fmri1 = split(/\//, $fmri1);
    my @fmri2 = split(/\//, $fmri2);
    my $i = @fmri1;
    my $j = @fmri2;

    while ($i > 0 and $j > 0) {
        $i--;
        $j--;
        return 0 if $fmri1[$i] ne $fmri2[$j];
    }
    return 1;
}

##############################################################################
# fmri_common(<ref_fmri1>, <ref_fmri2>, <re_match>)
#
# Checks to see if regular expression <re_match> matches against
# both FMRIs passed by reference.  If only one of the two FMRIs
# match the RE, then the text matching the RE is removed from
# the string that had the match.
#
# Returns 1 if both FMRIs matched the RE.
#
# This is not a public interface.
##############################################################################
sub fmri_common
{
    my ($fmri1, $fmri2, $re) = @_;

    my $match1 = ($$fmri1 =~ $re);
    my $match2 = ($$fmri2 =~ $re);
    if ($match1 xor $match2) {
        $$fmri1 =~ s/$re// if $match1;
        $$fmri2 =~ s/$re// if $match2;
    } else {
        return $match1;
    }
    return 0;
}

=back

=head1 SEE ALSO

B<IPS>(3), B<IPS::Version>(3), B<pkg>(5), B<pkgtree>(1).

=cut

1;
