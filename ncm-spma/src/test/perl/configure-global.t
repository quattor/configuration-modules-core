# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<call_entry_point> method, which in turn tests the
C<call_entry_point> method.

=head1 TESTS

o=head2 Successful executions

=over

=cut

BEGIN {
    use Carp qw(confess);
}

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor qw(valid_global default_packager nonexisting_packager
                     invalid_packager);
use NCM::Component::spma;
use Test::MockObject::Extends;
use CAF::Object;
use Set::Scalar;
use Class::Inspector;
use Carp qw(confess);
use Test::MockModule;

my $mock = Test::MockModule->new('NCM::Component::spma::yum');

$mock->mock('Configure', 'Configure');

$mock->mock('Unconfigure', 'Unconfigure');

=pod

=item * Valid packager in the profile

The packager is loaded and executed, and its success is propagated

=cut

my $cfg = get_config_for_profile("valid_global");
my $cmp = NCM::Component::spma->new('spma');
is($cmp->Configure($cfg), 'Configure', "Valid execution succeeded");

=pod

=item * Unconfigure is also called

=cut

$cmp = NCM::Component::spma->new('spma');
is($cmp->Unconfigure($cfg), 'Unconfigure', 'Unconfigure is also called');
=pod

=item * Packager not specified in the profile

The implementation defaults to yum.

=cut

$cmp = NCM::Component::spma->new('spma');
$cfg = get_config_for_profile('default_packager');
is($cmp->Configure($cfg), 'Configure', "Defaulting to Yum packager");

=pod

=item * The profile specifies a packager that does not exist

The component fails and reports it

=cut

$cmp = NCM::Component::spma->new('spma');
$cfg = get_config_for_profile("nonexisting_packager");
ok(!$cmp->Configure($cfg), "Non-existing packager triggers a failure");
is($cmp->{ERROR}, 1, "Error is reported");

=pod

=item * The profile specifies an invalid packager

The component fails and reports it

=cut

$cmp = NCM::Component::spma->new('spma');
$cfg = get_config_for_profile('invalid_packager');
ok(!$cmp->Configure($cfg), "Invalid packager triggers a failure");
is($cmp->{ERROR}, 1, "Error is reported");


=pod

=item * The packager fails

The error is propagated

=cut

$mock->mock('Configure', undef);
$cmp = NCM::Component::spma->new('spma');
$cfg = get_config_for_profile('valid_global');
ok(!$cmp->Configure($cfg), "Failure in underlying packager is triggered");

done_testing();


__END__

=pod

=back

=cut
