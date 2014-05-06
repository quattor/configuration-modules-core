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
                  "killall nscd")) {
    ok(!get_command($cmd), "Command $cmd is not executed if restart succeeds");
}

ok(get_command("service nscd restart"), "NSCD is always restarted");
ok(get_command("nscd -i passwd"), "NSCD cache is always cleaned");

set_command_status("service nscd restart", 1);

$cmp->restart_nscd();

foreach my $cmd (("service nscd stop", "service nscd start",
                  "killall nscd")) {
    ok(get_command($cmd), "Command $cmd is executed if restart fails");
}

done_testing();
