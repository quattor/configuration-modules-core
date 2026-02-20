# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<get_installed_rpms> method in NCM::Component::spma::dnf.
This method queries the RPM database and returns a C<Set::Scalar> with
all installed packages.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use Test::MockModule;
use NCM::Component::spma::dnf;
use CAF::Object;

$CAF::Object::NoAction = 1;

# Suppress error logging during failure tests
my $mock = Test::MockModule->new('NCM::Component::spma::dnf');
my $error_count = 0;
$mock->mock('error', sub { $error_count++; });

Readonly my $CMD => join(" ", NCM::Component::spma::dnf::RPM_QUERY_INSTALLED());

my $cmp = NCM::Component::spma::dnf->new("spma");

=pod

=head2 Test empty package list

=cut

set_desired_output($CMD, "");
set_desired_err($CMD, "");
set_command_status($CMD, 0);

my $pkgs = $cmp->get_installed_rpms();
isa_ok($pkgs, "Set::Scalar", "Received a Set::Scalar with empty input");
is($pkgs->size, 0, "Empty set returned for empty output");

=pod

=head2 Test with package list

=cut

set_desired_output($CMD, "glibc-0:2.28-151.el8.x86_64\nkernel-0:4.18.0-305.el8.x86_64\n");
set_desired_err($CMD, "");
set_command_status($CMD, 0);

$pkgs = $cmp->get_installed_rpms();
isa_ok($pkgs, "Set::Scalar", "Received a Set::Scalar");
is($pkgs->size, 2, "Set contains two packages");
ok($pkgs->has("glibc-0:2.28-151.el8.x86_64"), "Set contains glibc package");
ok($pkgs->has("kernel-0:4.18.0-305.el8.x86_64"), "Set contains kernel package");

=pod

=head2 Test RPM command failure

=cut

set_desired_output($CMD, "");
set_desired_err($CMD, "rpm: error");
set_command_status($CMD, 1);

$pkgs = $cmp->get_installed_rpms();
is($pkgs, undef, "Returns undef on RPM command failure");
is($error_count, 1, "Error reported on failure");

done_testing();
