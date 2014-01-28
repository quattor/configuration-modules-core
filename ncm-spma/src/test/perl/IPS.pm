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
# IPS module
# Author: Mark R. Bannister
#
# Routines for manipulating Solaris IPS package dependency trees.
#
##############################################################################
package IPS;

use strict;
use warnings;

use Carp;
use File::Basename;

our $CALL = basename($0);
our $DEBUG = 0;
our @PALETTE = ($ENV{PKGTREE_COL1} || "green",
                $ENV{PKGTREE_COL2} || "cyan",
                $ENV{PKGTREE_COL3} || "bold blue",
                $ENV{PKGTREE_COL4} || "magenta",
                $ENV{PKGTREE_COL5} || "red");

my (%pkg_depends, %pkg_dependants, %pkg_map, %pkg_list);
use constant CACHE_FILE => "/var/tmp/" . basename($0) . "." .
                                         getpwuid($<) . ".cache";
use constant USE_CACHE => 1;
use constant SYS_CATALOGUE => "/var/pkg/state/installed/catalog.dependency.C";

use IPS::Tree qw(load_tree load_tree_repo list_dependants list_depends
                 list_no_dependants get_installed_fmri);
use IPS::Package;
use IPS::Version;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(load_tree load_tree_repo list_dependants list_depends
                    list_no_dependants get_installed_fmri);

1;

__END__

=head1 NAME

IPS - IPS package dependency module

=head1 SYNOPSIS

  use IPS qw(load_tree list_dependants
             list_depends list_no_dependants
             get_installed_fmri);

  load_tree(cache => $cache_file, use_cache => 1);
  @output = list_depends(pkg => 'system/core-os');
  @output = list_dependants(pkg => 'system/core-os');
  @output = list_no_dependants(ntype => {incorporate => 1});
  print get_installed_fmri('system/core-os');

=head1 DESCRIPTION

These routines allow you to get the output of B<pkgtree> commands
from a Perl script.

=over 5

=item B<load_tree>([B<cache> => I<file_name>],
                   [B<use_cache> => I<use_cache>],
                   [B<force_cache> => I<force_cache>])

Loads raw package data into in-memory hashes required by the other
routines.  Caching is enabled by providing a file name
to be used for the cache and setting I<use_cache> to non-zero.
If the cache file is detected as stale, it will not be used.
Set I<force_cache> to non-zero if the cache file should always be
used even when it is stale.

A default cache filename is available for use in the constant
B<IPS::CACHE_FILE> which is set to
B</var/tmp/>I<basename>B<.>I<username>B<.cache>.

=item B<load_tree_repo>([B<cachedir> => I<dir_name>],
                        [B<use_cache> => I<use_cache>],
                        [B<force_cache> => I<force_cache>],
                        [B<pkg> => I<package_name>],
                        [B<ver> => I<package_version>],
                        [B<type> => { I<depend_types> }],
                        [B<ntype> => { I<not_depend_types> }],
                        [B<recurse> => I<recurse>],
                        [B<max-depth> => I<max_recursion_depth>])

Loads raw package data into in-memory hashes similar to B<load_tree>(),
except that latest data for the given package and its dependencies is obtained
from the IPS repositories and not from information on the installed system.
This is how the B<pkgtree --latest> option obtains its data.

=item B<list_depends>([B<pkg> => I<package_name>],
                      [B<ver> => I<package_version>],
                      [B<type> => { I<depend_types> }],
                      [B<ntype> => { I<not_depend_types> }],
                      [B<exact> => I<exact_only>],
                      [B<recurse> => I<recurse>],
                      [B<max-depth> => I<max_recursion_depth>],
                      [B<allow-repeats> => I<allow_repeats>],
                      [B<names> => I<names>],
                      [B<types> => I<types>],
                      [B<installed_only> => I<installed_only>])

Returns an array containing the lines of output that are displayed
by the B<pkgtree depends> command.  Arguments to the command
are encapsulated as the parameters names listed above.

=item B<list_dependants>([B<pkg> => I<package_name>],
                         [B<ver> => I<package_version>],
                         [B<type> => { I<depend_types> }],
                         [B<ntype> => { I<not_depend_types> }],
                         [B<exact> => I<exact_only>],
                         [B<recurse> => I<recurse>],
                         [B<max-depth> => I<max_recursion_depth>],
                         [B<allow-repeats> => I<allow_repeats>],
                         [B<names> => I<names>],
                         [B<types> => I<types>],
                         [B<installed_only> => I<installed_only>])

Returns an array containing the lines of output that are displayed
by the B<pkgtree dependants> command.  Arguments to the command
are encapsulated as the parameters names listed above.

=item B<list_no_dependants>([B<pkg> => I<package_name>],
                            [B<ver> => I<package_version>],
                            [B<type> => { I<depend_types> }],
                            [B<ntype> => { I<not_depend_types> }],
                            [B<exact> => I<exact_only>],
                            [B<recurse> => I<recurse>],
                            [B<installed_only> => I<installed_only>])

Returns an array containing the lines of output that are displayed
by the B<pkgtree no-dependants> command.  Arguments to the command
are encapsulated as the parameters names listed above.

=item B<get_installed_fmri>(B<pkg> => I<package_name>,
                            [B<all> => I<all>])

Returns the full FMRI of an installed package identified by the given
package name, which might be a partial match.  Relies on data in the
B<IPS::pkg_map> and B<IPS::pkg_list> hashes so will only work following
a successful call to B<load_tree>.

Set I<all> to 1 if an FMRI is required for any known package regardless
of whether the install flag is set.  This is useful when B<load_tree_repo>
has been used to populate the package hash.

=back

=head1 NOTES

The routines rely on global variables set in the module.  The
B<$IPS::CALL> variable will contain the basename of the executing
script, B<$IPS::DEBUG> should contain the debug level (or 0 to
disable debugging) and B<@IPS::PALETTE> is an array of five elements
containing the colour palette used by B<Term::ANSIColor>.

ANSI escape sequences for colour output will be included in the
arrays returned by the B<list_depends>, B<list_dependants> and
B<list_no_dependants> routines.  If colour is not desired,
set the environment variable B<ANSI_COLORS_DISABLED> to 1, e.g.

  $ENV{ANSI_COLORS_DISABLED} = 1 if ! -t STDOUT;

=head1 SEE ALSO

B<pkgtree>(1) or B<pkgtree -h>.

=cut
