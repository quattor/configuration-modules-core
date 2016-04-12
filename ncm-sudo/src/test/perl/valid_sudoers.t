use strict;
use warnings;
use Test::More;
use Test::Quattor;
# Don't mock CAF::Process here. We really need to run the visudo
# command to ensure valid configurations get detected.
$Test::Quattor::procs->unmock_all();
use NCM::Component::sudo;

use constant INVALID => "123445";
use constant VALID => "root ALL=(ALL) NOPASSWD: ALL\n";

=pod

=head1 DESCRIPTION

Test the ability to distinguish valid from invaild sudoers files.

=cut

my $cmp = NCM::Component::sudo->new('sudo');

ok($cmp->is_valid_sudoers(VALID), "Valid /etc/sudoers correctly recognized");
ok(!$cmp->is_valid_sudoers(INVALID), "Invalid /etc/sudoers correctly recognized");

done_testing();
