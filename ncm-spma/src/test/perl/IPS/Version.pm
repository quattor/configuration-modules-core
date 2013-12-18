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
# IPS::Version module
# Author: Mark R. Bannister
#
# Routines for manipulating Solaris IPS version strings.
#
##############################################################################
package IPS::Version;

use strict;
use warnings;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(version_match);

=head1 NAME

IPS::Version - IPS package version support module

=head1 SYNOPSIS

  use IPS;

  print "match\n" if IPS::Version::version_match(
              "0.5.11-0.175.1.0.0.24.2", "0.5.11");
  $s = IPS::Version::get_comp(
              "0.5.11,5.11-0.175.1.0.0.24.2:20120919T184427Z");
  $s = IPS::Version::get_build(
              "0.5.11,5.11-0.175.1.0.0.24.2:20120919T184427Z");
  $s = IPS::Version::get_branch(
              "0.5.11,5.11-0.175.1.0.0.24.2:20120919T184427Z");
  $s = IPS::Version::get_tstamp(
              "0.5.11,5.11-0.175.1.0.0.24.2:20120919T184427Z");

=head1 DESCRIPTION

Supporting routines used by B<pkgtree> to work with the version
component of an IPS package FMRI.

=over 5

=item B<version_match>(I<ver1>, I<ver2>, [B<exact> => I<exact>], [B<older> => I<older>])

Checks for two matching package versions.  By default, if
I<ver2> is newer than I<ver1> it will match too.

This behaviour may be modified by the I<exact> or I<older> arguments.
If I<exact> is set to 1 only exact versions will match.
If I<older> is set to 1, then if I<ver2> is older than I<ver1> it
will match (instead of if it is newer).

Returns 1 if there is a match, otherwise 0.

=cut

sub version_match
{
    my ($ver1, $ver2, $opt) = @_;

    print STDERR "version_match($ver1, $ver2, " . Dumper($opt) . ")\n"
        if $IPS::DEBUG > 2;

    #
    # Compare component version, build version, branch version
    # and timestamp in that order, if present
    #
    my $retval;

    if (!version_match_part(get_comp($ver1), get_comp($ver2), $opt) or
        !version_match_part(get_build($ver1), get_build($ver2), $opt) or
        !version_match_part(get_branch($ver1), get_branch($ver2), $opt)) {

        $retval = 0;
    } else {
        $retval = version_match_part(get_tstamp($ver1), get_tstamp($ver2),
                                     $opt);
    }
    print STDERR "version_match() returning: $retval\n" if $IPS::DEBUG > 2;
    return $retval;
}

=item B<get_comp>(I<ver>)

Get component number from IPS version string.

=cut

sub get_comp
{
    my ($ver) = @_;

    $ver =~ s/^([^,:-]*).*$/$1/;
    return $ver;
}

=item B<get_build>(I<ver>)

Get build number from IPS version string, or return blank string
if there is no build number.

=cut

sub get_build
{
    my ($ver) = @_;

    return '' if $ver !~ /,/;
    $ver =~ s/^.*,([^:-]*).*$/$1/;
    return $ver;
}

=item B<get_branch>(I<ver>)

Get branch number from IPS version string, or return blank string
if there is no branch number.

=cut

sub get_branch
{
    my ($ver) = @_;

    return '' if $ver !~ /-/;
    $ver =~ s/^.*-([^:]*).*$/$1/;
    return $ver;
}

=item B<get_tstamp>(I<ver>)

Get timestamp from IPS version string, or return blank string
if there is no timestamp.

=cut

sub get_tstamp
{
    my ($ver) = @_;

    return '' if $ver !~ /:/;
    $ver =~ s/^.*://;
    return $ver;
}

##############################################################################
# version_match_part(<ver1>, <ver2>, <exact>)
#
# Checks to see if a dot-separated version number matches another,
# or is newer.  If <exact> is 1, newer version numbers will not match.
#
# This is not a public interface.
##############################################################################
sub version_match_part
{
    my ($ver1, $ver2, $opt) = @_;
    my $exact = $opt->{exact} || 0;
    my $older = $opt->{older} || 0;
    my $retval = -1;

    print STDERR "version_match_part($ver1, $ver2, " . Dumper($opt) . ")\n"
        if $IPS::DEBUG > 2;

    # If either component is blank, this equates to a match
    if ($ver1 eq '' or $ver2 eq '') {
        $retval = 1;
    } elsif ($ver1 !~ /^[\d\.]*$/ or $ver2 !~ /^[\d\.]*$/) {
        # Not dot-separated number, do straight text comparison
        $retval = ($ver1 eq $ver2 ? 1 : 0);
    } else {
        my @ver1 = split(/\./, $ver1);
        my @ver2 = split(/\./, $ver2);
        my $i = 0;
        my $j = 0;

        for (;$retval == -1 and ($i < @ver1 or $j < @ver2); $i++, $j++) {
            my $v1 = $ver1[$i] || 0;
            my $v2 = $ver2[$j] || 0;
            next if $v1 == $v2;

            if ($exact) {
                $retval = 0;
            } else {
                return 1 if (($v2 > $v1) != $older);
                $retval = 0;
            }
        }
        $retval = 1 if $retval == -1;
    }
    print STDERR "version_match_part() returning: $retval\n"
                                                        if $IPS::DEBUG > 2;
    return $retval;
}

=back

=head1 SEE ALSO

B<IPS>(3), B<IPS::Package>(3), B<pkg>(5), B<pkgtree>(1).

=cut

1;
