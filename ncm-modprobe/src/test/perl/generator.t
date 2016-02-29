# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Ensure all C<process_*> methods are present.

A code generator creates and adds these methods.  In this test we
ensure they are there.

=cut

use strict;
use warnings;
use Test::More tests => 1;
use Test::Quattor;
use NCM::Component::modprobe;

my $cmp = NCM::Component::modprobe->new("modprobe");

can_ok($cmp, qw(process_alias process_install process_options process_remove process_blacklist));
