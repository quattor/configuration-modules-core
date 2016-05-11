# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test to ensure that schema validation rules for repository description are appropriate.

=head1 TESTS

=cut

use Test::More;
use Test::Quattor qw(repository_schema);
ok(1, "Would have failed earlier if schema was invalid");
done_testing;
