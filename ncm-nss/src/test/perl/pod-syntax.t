# -*- mode: cperl -*-
#
# Check that all POD is syntactically correct using Test::Pod.

use Test::More;
use Test::Pod;

my @dirs = qw(target/lib/perl target/doc/pod);
all_pod_files_ok(all_pod_files(@dirs));
