#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::Quattor qw(trivial_profile);
use Test::More;
use File::Path qw(mkpath);
use Cwd;
use NCM::Component::useraccess;
use CAF::Object;
use Class::Inspector;

$CAF::Object::NoAction = 1;

my @methods = grep(m{set_|init|files|pam},
		   @{Class::Inspector->functions(
						 'NCM::Component::useraccess')});

no warnings 'redefine';
no strict 'refs';

foreach my $method (@methods) {
    *{"NCM::Component::useraccess::$method"} = sub {
	my $self = shift;
	$self->{uc($method)}++;
	if (exists($self->{"RET_$method"})) {
	    if (ref($self->{"RET_$method"}) && wantarray) {
		return @{$self->{"RET_$method"}};
	    } else {
		return $self->{"RET_$method"};
	    }
	}
    };
};

use warnings 'redefine';
use strict 'refs';


=pod

=head1 DESCRIPTION

Test the C<Configure> method.

=head1 TESTS

=head2 Test the successful execution of the component.

=cut

my $cmp = NCM::Component::useraccess->new("useraccess");

my $cfg = get_config_for_profile('trivial_profile');
$cmp->{RET_initialize_user} = [0, 0, "/home/dir"];
$cmp->{RET_files} = { ssh_keys => 1 };
is($cmp->Configure($cfg), 1, "Configure runs succesfully");

foreach my $method (@methods) {
    is($cmp->{uc($method)}, 1, "Method $method was called");
}

=pod

=head2 Test for errors in any of the setter methods

=cut

my $errs = 0;
foreach my $method (grep(m{set_}, @methods)) {
    $cmp->{"RET_$method"} = -1;
    is($cmp->Configure($cfg), 0,
       "Errors in callee $method correctly propagated by the caller");
    is($cmp->{ERROR}, ++$errs, "Error in $method correctly reported");
    $cmp->{"RET_$method"} = 0;
}

=pod

=head2 Configuration of users that don't belong in the system

The component succeeds, but a message is nevertheless recorded.

=cut

$cmp->{RET_initialize_user} = undef;
is($cmp->Configure($cfg), 1, "Errors in initialize_user are not fatal");
is($cmp->{ERROR}, ++$errs, "Errors in initialize_user are reported");


done_testing();
