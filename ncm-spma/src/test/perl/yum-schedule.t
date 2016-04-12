# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<schedule> method.  This method adds an C<install $pkg>
or C<remove $pkg> line for each package.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;


my $cmp = NCM::Component::spma::yum->new("spma");

my @pkgs = qw(foo;a bar;b c);

my $txt = $cmp->schedule("install", \@pkgs);
like($txt, qr"^install", "Operation is printed");
like($txt, qr{\s*foo\.a\s*}, "Package foo is printed correctly");
like($txt, qr{\s*bar\.b\s*}, "Package bar is printed");
like($txt, qr{\s*c\s*}, "Package c with no arch is printed");
is(substr($txt, -1, 1), "\n", "String ends in newline");
$txt = $cmp->schedule("remove", \@pkgs);
like($txt, qr{^remove}, "Remove operation is printed");

is($cmp->schedule("remove", []), "",
   "Empty operation yields no command for the Yum shell");

done_testing();
