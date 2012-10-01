# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<schedule_install> method.  This method adds an
C<install $pkg> line for each package.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma;
use Test::Quattor;


my $cmp = NCM::Component::spma->new("spma");

my @pkgs = qw(foo-1.2.3 bar-4.5.6);

my $txt = $cmp->schedule("install", \@pkgs);
like($txt, qr"^install", "Operation is printed");
like($txt, qr{foo-1.2.3}, "Package foo is printed");
like($txt, qr{bar-4.5.6}, "Package bar is printed");
is(substr($txt, -1, 1), "\n", "String ends in newline");
$txt = $cmp->schedule("remove", \@pkgs);
like($txt, qr{^remove}, "Remove operation is printed");

done_testing();
