# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<restart_nscd> method.

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::authconfig;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::authconfig->new("authconfig");


$cmp->restart_nscd();

foreach my $cmd (("service nscd stop", "service nscd start",
                  "killall nscd", "nscd -i passwd")) {
    ok(get_command($cmd), "Command $cmd is executed");
}

done_testing();
