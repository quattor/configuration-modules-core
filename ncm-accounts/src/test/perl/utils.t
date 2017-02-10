use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::accounts;

=pod

=head1 DESCRIPTION

Test smaller functions, for the sake of completitude

=head1 TESTS

=head2 C<sanitize_path>

Used to ensure that the user's home path doesn't have any dangerous
characters


=cut

my $cmp = NCM::Component::accounts->new('accounts');

is($cmp->sanitize_path(";!·"), undef, "Insane path returns nothing");
is($cmp->{ERROR}, 1, "And an error is diagnosed");
is($cmp->sanitize_path("/home/foo"), "/home/foo", "Sane path returns a valid path");
is($cmp->sanitize_path("foo"), undef, "Relative paths are not accepted");

=pod

=head2 C<accounts_sort>

When possible, accounts should be printed in the same order as they
were in the system. Some broken software relies on this.

=cut

sub srt
{
    # The sort magic variables $a and $b are package globals
    ($NCM::Component::accounts::a, $NCM::Component::accounts::b) = @_;
    return NCM::Component::accounts::accounts_sort();
}


my $s = srt({name => 'a'}, {name => 'b'});
is($s, ('a' cmp 'b'), "Unnumbered accounts are compared by name");
$s = srt({name => 'a'}, {name => 'a'});
is($s, 0, "Unnumbered accounts are compared by name, and return 0 when they're the same");
$s = srt({name => 'a'}, {ln => 0, name => 'b'});
is($s, 1, "Numbered entries should go before unnumbered ones");
$s = srt({ln => 0, name => 'b'}, {name => 'a'});
is($s, -1, "Numbered entries really go before unnumbered ones");
$s = srt({name => 'a', ln => 10}, {ln => 0, name => 'b'});
is($s, (10 <=> 0), "Numbered entries are srted by number");
$s = srt({name => 'a', ln => 0}, {ln => 0, name => 'b'});
is($s, ('a' cmp 'b'), "Accounts with the same line are resolved by name");

done_testing();
