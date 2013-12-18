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
# IPS::Tree module
# Author: Mark R. Bannister
#
# Routines for manipulating Solaris IPS package dependency trees.
# The perldoc for these routines can be found in the parent IPS module.
#
##############################################################################
package IPS::Tree;

use strict;
use warnings;

use Carp;
use Term::ANSIColor;
use Fcntl ":mode";
use File::Temp;
use IPS::Package qw(pkg_add_lookup pkg_lookup pkg_lookup_installed fmri_match);
use IPS::Version qw(version_match);

use Data::Dumper;
$Data::Dumper::Terse = 1;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(load_tree load_tree_repo list_dependants list_depends
                    list_no_dependants get_installed_fmri);

use constant PKG_CONTENTS => "(/usr/bin/pkg list -Hv; " .
                 "/usr/bin/pkg contents -Ht depend -o type,fmri,pkg.fmri)";

use constant PKG_LIST_ALL => "/usr/bin/pkg list -afHv";
use constant PKG_CONTENTS_ALL =>
                 "/usr/bin/pkg contents -Ht depend -o type,fmri,pkg.fmri -r ";

##############################################################################
# load_tree([cache => <cache>], [use_cache => <use_cache>],
#           [force_cache => <force_cache>],
#           [static => <static>], [no_preload => <no_preload>])
#
# Populates pkg_depends and pkg_dependants hashes.
#
# Options:
#       cache          Name of cache file to use.
#       use_cache      >0 to use cache.
#       force_cache    >0 to always use cache even if it is stale.
#       static         >0 loads data from cache file only, and does not
#                      run any external pkg commands.
#       no_preload     >0 to instruct this routine not to pre-populate
#                      the pkg_depends hash when processing the output of
#                      the pkg list command.
##############################################################################
sub load_tree
{
    my %opt = @_;

    print STDERR "load_tree(" . Dumper(\%opt) . ")\n" if $IPS::DEBUG;
    return if $opt{static} and (!$opt{cache} or !$opt{use_cache});

    my $load_dep = sub
    {
        my ($pkg_fmri, $pkg_name, $pkg_ver, $dep_type, $dep_fmri) = @_;

        #
        # Update hash with this package
        #
        for my $s (pkg_lookup($pkg_name)) {
            my @fmri_lst = split(/@/, $dep_fmri);
            for my $s2 (pkg_lookup($fmri_lst[0])) {
                my $s3 = "$s2";
                $s3 .= "\@$fmri_lst[1]" if $fmri_lst[1];
                $IPS::pkg_depends{$s}{$pkg_ver}{$dep_type}{$s3} = 1;
            }
        }

        #
        # Update hash with the package we are depending on
        #
        my ($dep_name, $dep_ver) = split(/@/, $dep_fmri);
        for my $s (pkg_lookup($dep_name)) {
            my @fmri_lst = split(/@/, $pkg_fmri);
            for my $s2 (pkg_lookup($fmri_lst[0])) {
                my $s3 = "$s2";
                $s3 .= "\@$fmri_lst[1]" if $fmri_lst[1];
                $IPS::pkg_dependants{$s}{$dep_ver || '-'}{$dep_type}{$s3} = 1;
            }
        }
    };

    #
    # Process each line from PKG_CONTENTS output or cache file
    #
    my $contents;
    if ($opt{use_cache} and $opt{cache}) {
        #
        # From cache file
        #
        if (-e $opt{cache} and -e IPS::SYS_CATALOGUE and !$opt{force_cache}) {
            #
            # Package catalogue is newer than cache file,
            # so we should clear the cache file
            #
            my $cache_modtime = -M $opt{cache};
            my $sys_modtime = -M IPS::SYS_CATALOGUE;
            unlink($opt{cache}) if $sys_modtime < $cache_modtime;
        }

        my $clear_cache = 0;
        if (-e $opt{cache}) {
            if (! -o $opt{cache}) {
                #
                # Remove the cache file if it is owned by another UID
                #
                $clear_cache = 1;
            } else {
                #
                # Remove the cache file if it is writable by another UID
                #
                my $mode = (stat($opt{cache}))[2];
                $clear_cache = 1 if ($mode & S_IWGRP) or ($mode & S_IWOTH);
            }
            unlink($opt{cache}) if $clear_cache;
        }

        if (! -e $opt{cache} or $clear_cache) {
            return if $opt{static};

            #
            # Create cache file with .new suffix first so we don't
            # risk ending up with partial data if the process
            # is terminated prematurely
            #
            my $cmd = PKG_CONTENTS . " > $opt{cache}.new";
            `$cmd`;
            if ($?) {
                unlink("$opt{cache}.new");
                confess "$IPS::CALL: /usr/bin/pkg: bad exit status: $!";
            }
            rename("$opt{cache}.new", $opt{cache}) or
                confess "$IPS::CALL: cannot rename cache file: $!";
        }
        open($contents, "<", $opt{cache})
                or confess "$IPS::CALL: could not read '$opt{cache}': $!";
    } else {
        #
        # From pipeline
        #
        open($contents, "-|", PKG_CONTENTS)
                or confess "$IPS::CALL: /usr/bin/pkg: could not open pipe: $!";
    }

    for my $line (<$contents>) {
        chomp $line;
        if (substr($line, 0, 4) eq 'pkg:') {
            #
            # Save full package FMRI to lookup table, this output came from the
            # pkg list command and we prepopulate full FMRIs first so that we
            # can convert any partial FMRIs we find in the package manifests
            #
            my @fields = split / /, $line;
            my $fmri = $fields[0];
            my $installed = 0;
            $installed = 1 if $fields[-1] =~ /^i/;

            my ($pkg_name, $pkg_ver) = split(/@/, $fmri);
            $IPS::pkg_list{$pkg_name} = $pkg_ver if !$IPS::pkg_list{$pkg_name};
            pkg_add_lookup($pkg_name, $installed);
            $IPS::pkg_depends{$pkg_name}{$pkg_ver} ||= {} if !$opt{no_preload};
        } else {
            $line =~ s/, /|/g;
            my ($dep_type, $fmri_list, $pkg_fmri) = split(/\s+/, $line, 3);
            $fmri_list =~ s/[]'[]//g;

            #
            # Save package FMRI from manifest that we are processing
            #
            my ($pkg_name, $pkg_ver) = split(/@/, $pkg_fmri);

            #
            # Iterate each FMRI as require-any dependencies
            # will have more than one
            #
            for my $fmri (split(/\|/, $fmri_list)) {
                $load_dep->($pkg_fmri, $pkg_name, $pkg_ver, $dep_type, $fmri);
            }
        }
    }
    close($contents) or confess "$IPS::CALL: error getting pkg data: $!";
}

##############################################################################
# load_tree_repo([cachedir => <cachedir>], [use_cache => <use_cache>],
#                [force_cache => <force_cache>],
#                [pkg => <pkg>], [ver => <ver>],
#                [type => <type>], [ntype => <ntype>],
#                [recurse => <recurse>], [max-depth => <max-depth>])
#
# Populates pkg_depends hash using latest data from IPS repositories for the
# given package.
#
# Options:
#       cachedir       Name of cache directory to use.
#       use_cache      >0 to use cache.
#       force_cache    >0 to always use cache even if it is stale.
#       pkg            Load dependency information for this package name.
#       ver            Load dependency information for this package version.
#       type           Load data only for given dependency types.
#       ntype          Load data for all but given dependency types.
#       recurse        Load recursive dependencies.
#       max-depth      Number of levels to recurse to. Default -1 is unlimited.
##############################################################################
sub load_tree_repo
{
    my %opt = @_;

    print STDERR "load_tree_repo(" . Dumper(\%opt) . ")\n" if $IPS::DEBUG;

    my $cachedir = $opt{cachedir};
    $cachedir = File::Temp->newdir() if ! $cachedir;
    if (! -d $cachedir) {
        mkdir($cachedir, 0700) or
            confess "$IPS::CALL: cannot create directory '$cachedir': $!";
    }

    #
    # Load in whatever data is already in the cache file
    #
    load_tree(cache => "$cachedir/cache", use_cache => $opt{use_cache},
              force_cache => $opt{force_cache}, static => 1);

    #
    # Parse the output of the PKG_LIST_ALL command
    #
    if (! -e "$cachedir/all") {
        print STDERR "load_tree_repo() fetching package list ...\n"
                     if $IPS::DEBUG;

        my $cmd = PKG_LIST_ALL . " > $cachedir/all.new";
        `$cmd`;
        confess "$IPS::CALL: /usr/bin/pkg: bad exit status: $!" if $?;
        rename("$cachedir/all.new", "$cachedir/all") or
            confess "$IPS::CALL: cannot rename cache file: $!";
    }
    load_tree(cache => "$cachedir/all", use_cache => 1,
              force_cache => 1, static => 1, no_preload => 1);

    #
    # Expand list of dependencies (one level at a time if recursing)
    #
    my $fmri = $opt{pkg};
    $fmri .= "\@$opt{ver}" if $opt{ver};
    my @get_depends = ($fmri);

    my $filter_type = $opt{type};
    my $filter_ntype = $opt{ntype};
    my $depth = 0;
    my $max_depth = -1;
    $max_depth = $opt{'max-depth'} if defined $opt{'max-depth'};

    while (@get_depends and (++$depth < $max_depth or $max_depth < 0)) {
        my @need_depends = ();

        for my $fmri (@get_depends) {
            #
            # Get latest version of requested package
            #
            $fmri = get_installed_fmri($fmri, 1);
            next if !$fmri;

            my ($pkg, $ver) = split(/@/, $fmri);
            next if $IPS::pkg_depends{$pkg}{$ver};  # already in hash
            $IPS::pkg_depends{$pkg}{$ver} = {};
            push @need_depends, $fmri;
        }
        last if !@need_depends;

        #
        # Get list of dependencies for the set of packages
        # in the @need_depends array
        #
        print STDERR "load_tree_repo() fetching " . scalar(@need_depends) .
                     " item(s) from catalogue ...\n" if $IPS::DEBUG;

        my $temp_contents = File::Temp->new();
        my $tmpfile = $temp_contents->filename;

        my $cmd = PKG_CONTENTS_ALL . join(" ", @need_depends) .
                                     " > $tmpfile 2> /dev/null";
        `$cmd`;
        confess "$IPS::CALL: /usr/bin/pkg: bad exit status: $!" if $?;
        load_tree(cache => $tmpfile, use_cache => 1,
                  force_cache => 1, static => 1);

        #
        # If recursing, now repeat the above for any
        # new dependencies just read into the hash
        #
        @get_depends = ();
        if ($opt{recurse}) {
            for my $fmri (@need_depends) {
                my ($name, $ver) = split(/@/, $fmri);
                for my $type (keys %{$IPS::pkg_depends{$name}{$ver}}) {
                    next if ($type eq 'incorporate');
                    next if ($filter_type and !$filter_type->{$type});
                    next if ($filter_ntype and $filter_ntype->{$type});

                    for my $dep_fmri (keys
                            %{$IPS::pkg_depends{$name}{$ver}{$type}}) {
                        push @get_depends, $dep_fmri;
                    }
                }
            }
        }
    }

    #
    # Write cache file
    #
    if ($opt{use_cache} and $opt{cachedir}) {
        print STDERR "load_tree_repo() writing to cache dir: $opt{cachedir}\n"
                     if $IPS::DEBUG > 1;
        open(my $contents, ">", "$opt{cachedir}/cache.new")
            or confess "$IPS::CALL: could not write to " .
                       "'$opt{cachedir}/cache.new': $!";
        for my $name (keys %IPS::pkg_depends) {
            my $pkg_hash = $IPS::pkg_depends{$name};
            for my $ver (keys %$pkg_hash) {
                for my $type (keys %{$pkg_hash->{$ver}}) {
                    for my $dep_fmri (keys %{$pkg_hash->{$ver}->{$type}}) {
                        print $contents "$type $dep_fmri $name\@$ver\n";
                    }
                }
            }
        }
        close($contents) or confess "$IPS::CALL: error writing cache: $!";
        rename("$opt{cachedir}/cache.new", "$opt{cachedir}/cache") or
            confess "$IPS::CALL: cannot rename cache file: $!";
    }
}

##############################################################################
# list_header(<output>, <tcol>, <type>, <name>, <ver>)
#
# Push package header with appropriate colour scheme to given output array.
#
# This is not a public interface.
##############################################################################
sub list_header
{
    my ($output, $tcol, $type, $name, $ver) = @_;
    push @$output, colored("|------(", $IPS::PALETTE[$tcol]) .
        sprintf(colored("%11s", "bold $IPS::PALETTE[$tcol+1]"), $type) .
        colored(")--", $IPS::PALETTE[$tcol]) .
        colored("$name", "bold $IPS::PALETTE[$tcol+1]") .
        (!$ver or $ver eq '-' ? "\n" :
                colored("\@$ver\n", "bold $IPS::PALETTE[$tcol+1]"));
}

##############################################################################
# list_process(<hash>, <option> => <value>, ...)
#
# Lists packages in the given package hash that has been previously
# populated by load_tree(), and display their dependencies.
#
# Options filter the results:
#      pkg            Filter by package name.
#      ver            Filter by package version.
#      type           Filter by hash of depend types.
#      ntype          Filter by hash of depend types NOT to include.
#      exact          Restrict to exact versions only.
#
# Additional non-filtering options:
#      recurse        Expand each entry recursively.
#      max-depth      Number of levels to recurse to. Default -1 is unlimited.
#      allow-repeats  Remove safeties and allow infinite recursion.
#      names          List FMRIs only.
#      types          List FMRIs and dependency types only.
#      installed_only
#                     Only process packages which are actually installed
#                     on the system.  This is the case anyway unless
#                     load_tree_repo() has been used which populates
#                     information about latest package versions into
#                     the internal hash structures.
#
# Internals used when recursing:
#      depth          Current depth if recursing.
#
# Internals used by calling subroutines:
#      top            0 = display subject package at bottom of dependency list
#                         (for viewing dependants).
#                     1 = display subject package at top of dependency list
#                         (for viewing depends).
#      loopcheck      unique hashref used for depth limiting.
#      names_seen     unique hashref used to dedup names listing.
##############################################################################
sub list_process
{
    my ($hash, %opt) = @_;

    print STDERR "list_process(" . Dumper(\%opt) . ")\n" if $IPS::DEBUG > 1;

    my $filter_pkg = $opt{pkg};
    my $filter_ver = $opt{ver};
    my $filter_type = $opt{type};
    my $filter_ntype = $opt{ntype};
    my $top = $opt{top};
    my $recurse = $opt{recurse};
    my $names = $opt{names};
    my $types = $opt{types};
    my $installed_only = $opt{installed_only};
    $names = 1 if $types;
    my $max_depth = -1;
    $max_depth = $opt{'max-depth'} if defined $opt{'max-depth'};
    my $depth = $opt{depth} || 0;
    my $tcol = $depth%2*2;

    my $loopcheck = $opt{loopcheck};
    my $names_seen = $opt{names_seen};

    my @output = ();
    my @pkg_keys = ();

    if ($filter_pkg) {
        unless ($installed_only) {
            @pkg_keys = pkg_lookup($filter_pkg);
        } else {
            @pkg_keys = pkg_lookup_installed($filter_pkg);
        }
    } else {
        @pkg_keys = keys %$hash;
    }

    my %vopt;
    $vopt{exact} = $opt{exact} || 0;
    $vopt{older} = $top;

    for my $name (@pkg_keys) {
        my $pkg_hash = $hash->{$name};
        for my $ver (keys %$pkg_hash) {
            next if ($filter_ver and !version_match($ver, $filter_ver, \%vopt));
            for my $type (keys %{$pkg_hash->{$ver}}) {
                next if ($filter_type and !$filter_type->{$type});
                next if ($filter_ntype and $filter_ntype->{$type});

                if (!$names) {
                    #
                    # Output header line for this package (if top-posting)
                    #
                    push @output, "\n" if !$depth;
                    list_header(\@output, $tcol, $type, $name, $ver) if $top;
                } elsif ($depth) {
                    #
                    # Output subject package FMRI if listing names
                    # or types only, we are recursing, and this is
                    # not a top-level node
                    #
                    my $name_key = ($types ? "$type " : "") . $name .
                                   ($ver and $ver ne "-" ? "\@$ver" : "");
                    if (!$names_seen->{$name_key}) {
                        $names_seen->{$name_key} = 1;
                        push @output,
                             ($types ? colored("$type ", $IPS::PALETTE[2])
                                     : "") .
                             colored($name, $IPS::PALETTE[0]) .
                                 ($ver and $ver ne "-" ?
                                 colored("\@$ver", $IPS::PALETTE[1]) : "") .
                             "\n";
                    }
                }

                for my $dep_fmri (keys %{$pkg_hash->{$ver}->{$type}}) {
                    #
                    # Recurse if requested and if we haven't already reached
                    # maximum depth
                    #
                    my $flag = '';

                    if ($recurse and $type ne 'incorporate') {
                        if (!$opt{'allow-repeats'} and
                                 $loopcheck->{$dep_fmri}) {
                            $flag = ' **';
                        } elsif ($max_depth > -1 and $depth >= $max_depth) {
                            $flag = ' >>';
                        } else {
                            $flag = 'r';
                        }
                    }

                    my @deps = split /@/, $dep_fmri;
                    if ($flag eq 'r') {
                        $loopcheck->{$dep_fmri} = 1 if !$opt{'allow-repeats'};
                        my %editopt = %opt;
                        $editopt{pkg} = $deps[0];
                        $editopt{ver} = $deps[1] || '';
                        $editopt{depth} = $depth + 1;
                        my @block = list_process($hash, %editopt);

                        if (!@block) {
                            #
                            # If the recursive call returned nothing, then
                            # we have reached the bottom of the branch
                            #
                            $flag = '';
                        } else {
                            #
                            # Process the output block from the recursive call
                            #
                            map($_ = colored("|", $IPS::PALETTE[$tcol]) . "$_",
                                @block) if !$names;
                            push @output, @block;
                        }
                    }

                    #
                    # Output FMRI of dependency
                    #
                    if (!$names) {
                        #
                        # With indentation and flags
                        #
                        my $dep_col_fmri = colored("| $deps[0]",
                                                   $IPS::PALETTE[$tcol]) .
                            (@deps == 1 ? "" : colored("\@$deps[1]",
                                                   $IPS::PALETTE[$tcol+1]));

                        push @output, $dep_col_fmri .
                            (!$flag ? "" : colored($flag, $IPS::PALETTE[4])) .
                                "\n" if $flag ne 'r';
                    } else {
                        my $name_key = ($types ? "$type " : "") . $deps[0] .
                                       (@deps == 1 ? "" : "\@$deps[1]");
                        if (!$names_seen->{$name_key}) {
                            #
                            # Without indentation nor flags
                            #
                            $names_seen->{$name_key} = 1;
                            push @output,
                                 ($types ? colored("$type ", $IPS::PALETTE[2])
                                         : "") .
                                 colored("$deps[0]", $IPS::PALETTE[0]) .
                                     (@deps == 1 ? "" :
                                      colored("\@$deps[1]", $IPS::PALETTE[1])) .
                                 "\n";
                        }
                    }
                }

                #
                # Output footer line for this package (if bottom-posting)
                #
                list_header(\@output, $tcol, $type, $name, $ver)
                    if !$top and !$names;
            }
        }
    }

    return @output;
}

##############################################################################
# list_dependants(<option> => <value>, ...)
#
# Lists packages in the pkg_dependants hash that has been previously
# populated by load_tree().  See list_process() for options.
##############################################################################
sub list_dependants
{
    my %opt = @_;
    print STDERR "list_dependants(" . Dumper(\%opt) . ")\n" if $IPS::DEBUG > 0;
    return list_process(\%IPS::pkg_dependants, %opt, top => 0,
                        loopcheck => {}, names_seen => {});
}

##############################################################################
# list_depends(<option> => <value>, ...)
#
# Lists packages in the pkg_depends hash that has been previously
# populated by load_tree().  See list_process() for options.
##############################################################################
sub list_depends
{
    my %opt = @_;
    print STDERR "list_depends(" . Dumper(\%opt) . ")\n" if $IPS::DEBUG > 0;
    return list_process(\%IPS::pkg_depends, %opt, top => 1,
                        loopcheck => {}, names_seen => {});
}

##############################################################################
# list_no_dependants([pkg => <pkg>], [ver = <ver>]
#                    [type => <type>], [ntype => <ntype>],
#                    [exact => <exact>], [recurse => <recurse>],
#                    [installed_only => <installed_only>])
#
# Lists packages with no dependants.
#
# Options filter the results:
#       pkg      Filter by package name
#       ver      Filter by package version
#       type     Filter by hash of depend types
#       ntype    Filter by hash of depend types NOT to include.
#       exact    Restrict to exact versions only.
#
# Additional non-filtering options:
#       recurse  For all packages that match the filter, test for
#                ring fenced dependencies and report all additional
#                FMRIs that are not required by any external package.
#       installed_only
#                Only process packages which are actually installed
#                on the system.  This is the case anyway unless
#                load_tree_repo() has been used which populates
#                information about latest package versions into
#                the internal hash structures.
##############################################################################
sub list_no_dependants
{
    my %opt = @_;

    print STDERR "list_no_dependants(" . Dumper(\%opt) . ")\n"
        if $IPS::DEBUG > 0;

    my $filter_pkg = $opt{pkg};
    my $filter_ver = $opt{ver};
    my $filter_type = $opt{type};
    my $filter_ntype = $opt{ntype};
    my $exact = $opt{exact};
    my $recurse = $opt{recurse};
    my $installed_only = $opt{installed_only};

    my @output = ();

    for my $name (keys %IPS::pkg_depends) {
        next if ($filter_pkg and !fmri_match($name, $filter_pkg));
        for my $ver (keys %{$IPS::pkg_depends{$name}}) {
            next if ($filter_ver and !version_match($ver, $filter_ver, \%opt));

            if (!list_dependants(pkg => $name, ver => $ver,
                                 type => $filter_type,
                                 ntype => $filter_ntype,
                                 exact => $exact,
                                 installed_only => $installed_only)) {

                push @output, colored("$name", $IPS::PALETTE[0]) .
                              colored("\@$ver", $IPS::PALETTE[1]) . "\n";

                #
                # Detect ring fenced dependencies and report these FMRIs too
                #
                push @output, ring_fence(pkg => $name, ver => $ver,
                                         type => $filter_type,
                                         ntype => $filter_ntype,
                                         exact => $exact,
                                         installed_only => $installed_only)
                                                                    if $recurse;
            }
        }
    }

    return @output;
}

##############################################################################
# ring_fence([pkg => <pkg>], [ver = <ver>]
#            [type => <type>], [ntype => <ntype>],
#            [exact => <exact>], [installed_only => <installed_only>)
#
# Detects ring fenced dependencies, and report all additional
# FMRIs that are not required by any external package.
#
# This is not a public interface.
##############################################################################
sub ring_fence
{
    my (%opt) = @_;

    print STDERR "ring_fence(" . Dumper(\%opt) . ")\n" if $IPS::DEBUG > 1;

    my $filter_pkg = $opt{pkg};
    my $filter_ver = $opt{ver};
    my $filter_type = $opt{type};
    my $filter_ntype = $opt{ntype};
    my $exact = $opt{exact};
    my $installed_only = $opt{installed_only};

    my $save_colour_mode = $ENV{ANSI_COLORS_DISABLED};
    $ENV{ANSI_COLORS_DISABLED} = 1;

    #
    # Start by gathering a recursive list of all packages
    # that this particular package depends upon
    #
    my @depends = list_depends(pkg => $filter_pkg, ver => $filter_ver,
                               type => $filter_type, ntype => $filter_ntype,
                               exact => $exact, recurse => 1, names => 1,
                               installed_only => $installed_only);
    chomp(@depends);

    #
    # Turn the list into a hash so we can flag a package as tainted
    # if it has any external dependency
    #
    my %ringmap = map { (split /@/)[0] => 1 } @depends;
    $ringmap{$filter_pkg} = 1;

    #
    # Repeat the outer loop for as long as
    # a taint flag was changed for some package,
    # to ensure trickle-down
    #
    my $changed = 1;
    while ($changed) {
        $changed = 0;
        for (@depends) {
            my ($name, $ver) = split /@/;
            next if !$ringmap{$name};  # this package is already tainted

            #
            # Get list of dependant packages
            #
            my @dependants = list_dependants(pkg => $name, ver => $ver,
                                   type => $filter_type, ntype => $filter_ntype,
                                   exact => $exact, names => 1,
                                   installed_only => $installed_only);

            for (@dependants) {
                my $dep_pkg = (split /@/)[0];
                if (!$ringmap{$dep_pkg}) {
                    #
                    # A package outside of the ring fence depends on this
                    # package, so mark it as tainted
                    #
                    $ringmap{$name} = 0;
                    $changed = 1;
                    last;
                }
            }
        }
    }

    $ENV{ANSI_COLORS_DISABLED} = $save_colour_mode;

    #
    # Now loop through the depends array and output only
    # those packages that were not tainted
    #
    my (@output, %pkg_seen);
    for my $pkg_fmri (@depends) {
        $pkg_fmri = get_installed_fmri($pkg_fmri, !$installed_only);
        if ($pkg_fmri) {
            my ($name, $ver) = split(/@/, $pkg_fmri);
            if ($ringmap{$name} and !$pkg_seen{$pkg_fmri}) {
                $pkg_seen{$pkg_fmri} = 1;
                push @output, colored("$name", $IPS::PALETTE[0]) .
                              colored("\@$ver", $IPS::PALETTE[1]) . "\n";
            }
        }
    }

    return @output;
}

##############################################################################
# get_installed_fmri(<pkg>, [<all>])
#
# Takes name component from given <pkg> and returns full FMRI of matching
# package if it is already installed.  Relies on data in the IPS::pkg_map
# and IPS::pkg_list hashes so will only work following a successful call
# to load_tree().
#
# Set <all> to 1 if an FMRI is required for any known package regardless
# of whether the install flag is set.  This is useful when load_tree_repo()
# has been used to populate the package hash.
##############################################################################
sub get_installed_fmri
{
    my ($pkg, $all) = @_;

    my @pkgs;
    $pkg =~ s/@.*$//;
    unless ($all) {
        @pkgs = pkg_lookup_installed($pkg);
    } else {
        @pkgs = pkg_lookup($pkg);
    }

    my $name = $pkgs[0];
    my $ver;
    $ver = ${IPS::pkg_list{$name}} if $name;
    return "$name\@$ver" if $ver;
}

1;
