#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::Quattor;
use Test::More;
use File::Path qw(mkpath);
use Cwd;
use NCM::Component::useraccess;
use CAF::Object;
use Class::Inspector;

$CAF::Object::NoAction = 1;

my @methods = grep(m{set_(?!roles)},
		   @{Class::Inspector->functions(
						 'NCM::Component::useraccess')});

no warnings 'redefine';
no strict 'refs';

foreach my $method (@methods) {
    *{"NCM::Component::useraccess::$method"} = sub {
	my $self = shift;
	$self->{uc($method)}++;
	return $self->{"RET_$method"};
    };
};

use warnings 'redefine';
use strict 'refs';


=pod

=head1 DESCRIPTION

Test the C<set_roles> method.

=head1 TESTS

=head2 Test the successful setting of roles

=cut

my $cmp = NCM::Component::useraccess->new("useraccess");

my $fhash = { SSH_KEYS => 1 };

my $belongsto = [qw(simpsons)];

my $roles = {simpsons => { roles => []}};

is($cmp->set_roles("homer", $belongsto, $roles, $fhash), 0,
   "Correctly defined the roles for a user");

foreach my $method (@methods) {
    is($cmp->{uc($method)}, 1, "Method $method was called");
}

=pod

=head2 Test the correct propagation of errors

If any callee fails, the method should report it. We assume here a
leaf role. Writing a test for errors inside a recursive call to
C<set_roles> is not worth the effort.

=cut

my $old;
foreach my $method (@methods) {
    $cmp->{"RET_$method"} = -1;
    if ($old) {
	$cmp->{"RET_$old"} = 0;
    }
    is($cmp->set_roles("homer", $belongsto, $roles, $fhash), -1,
       "Errors in a callee $method correctly propagated by the caller");
    $old = $method;
}

done_testing();
