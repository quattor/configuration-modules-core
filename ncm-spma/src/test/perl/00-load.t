# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Smoke test

Basic test that ensures that our module will load correctly.

B<Do not disable this test>. And do not push anything to SF without
having run, at least, this test.

=cut

use strict;
use warnings;
use Test::More tests => 4;

use_ok("NCM::Component::spma");
use_ok("NCM::Component::spma::yum");
use_ok("NCM::Component::spma::ips");
use_ok("NCM::Component::spma::yum_ng");
