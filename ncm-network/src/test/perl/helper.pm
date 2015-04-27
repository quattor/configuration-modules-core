# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

=pod

=head1 helper module

disables sleep to speed up the tests.
sets NoAction (use after Test::Quattor, otherwise breaks CCM)

=cut

package helper;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use strict;
use warnings;
use CAF::Object;

$CAF::Object::NoAction = 1;

1;

