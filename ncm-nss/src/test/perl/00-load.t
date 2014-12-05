# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Smoke test

Basic test that ensures that our module will load correctly.

=cut

use strict;
use warnings;
use Test::More tests => 1;

use_ok('NCM::Component::nss');
