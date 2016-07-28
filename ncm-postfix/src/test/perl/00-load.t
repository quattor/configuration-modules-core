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
use Test::Quattor;

use Test::Quattor::TextRender::Base;
$CAF::Object::NoAction = 1;
my $caf_trd = mock_textrender();

use_ok("NCM::Component::postfix");
