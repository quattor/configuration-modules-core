# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Testing modules installation/upgrade

Tests that the install_modules function does its job properly. Three possible scenarios are tested.

=cut

use strict;
use warnings;
use NCM::Component::puppet;
use Test::More tests => 9;
use Test::Quattor;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $comp = NCM::Component::puppet->new('puppet');

use Readonly;
Readonly::Scalar my $UPGRADE =>'puppet module upgrade';
Readonly::Scalar my $INSTALL =>'puppet module install';

=pod

=over 4

=item * The module exists and it is installed (3 tests):

=over 4

=item * tests that the "puppet upgrade" command is invoked (set it to exit with status 0);

=item * tests that the "puppet install" command is not invoked;

=item * tests that no error is raised by the component.

=back

=cut

set_desired_output("$UPGRADE INSTALLED_MODULE","stdout");
set_desired_err("$UPGRADE INSTALLED_MODULE","stderr");
set_command_status("$UPGRADE INSTALLED_MODULE",0);
set_desired_output("$INSTALL INSTALLED_MODULE","stdout");
set_desired_err("$INSTALL INSTALLED_MODULE","stderr");
set_command_status("$INSTALL INSTALLED_MODULE",0);


=pod

=item * The module exists and it is not installed (3 tests):

=over 4

=item * tests that the "puppet upgrade" command is invoked (set it to exit with status 1);

=item * tests that the "puppet install" command is invoked (set it to exit with status 0);

=item * tests that no error is raised by the component.

=back

=cut

set_desired_output("$UPGRADE NOT_INSTALLED_MODULE","stdout");
set_desired_err("$UPGRADE NOT_INSTALLED_MODULE","stderr");
set_command_status("$UPGRADE NOT_INSTALLED_MODULE",1<<8);
set_desired_output("$INSTALL NOT_INSTALLED_MODULE","stdout");
set_desired_err("$INSTALL NOT_INSTALLED_MODULE","stderr");
set_command_status("$INSTALL NOT_INSTALLED_MODULE",0);

=pod

=item * The module does not exist (3 tests):

=over 4

=item * tests that the "puppet upgrade" command is invoked (set it to exit with status 1);

=item * tests that the "puppet install" command is invoked (set it to exit with status 1);

=item * tests that an error is raised by the component.

=back

=back

=cut

set_desired_output("$UPGRADE NOT_EXISTING_MODULE","stdout");
set_desired_err("$UPGRADE NOT_EXISTING_MODULE","stderr");
set_command_status("$UPGRADE NOT_EXISTING_MODULE",1<<8);
set_desired_output("$INSTALL NOT_EXISTING_MODULE","stdout");
set_desired_err("$INSTALL NOT_EXISTING_MODULE","stderr");
set_command_status("$INSTALL NOT_EXISTING_MODULE",1<<8);


$comp->install_modules({INSTALLED_MODULE => {},NOT_INSTALLED_MODULE=>{}});

ok(defined(get_command("$UPGRADE INSTALLED_MODULE")), "module upgrade is invoked on installed module");
ok(!defined(get_command("$INSTALL INSTALLED_MODULE")), "module install is not invoked on installed module");
ok(!exists($comp->{ERROR}), "No errors in normal execution");

ok(defined(get_command("$UPGRADE NOT_INSTALLED_MODULE")), "module upgrade is invoked on not installed module");
ok(defined(get_command("$INSTALL NOT_INSTALLED_MODULE")), "module install is invoked on not installed module");
ok(!exists($comp->{ERROR}), "No errors found in normal execution");

$comp->install_modules({INSTALLED_MODULE => {},NOT_EXISTING_MODULE=>{}});

ok(defined(get_command("$UPGRADE NOT_EXISTING_MODULE")), "module upgrade is invoked on non existing module");
ok(defined(get_command("$INSTALL NOT_EXISTING_MODULE")), "module install is invoked on non existing module");
ok(exists($comp->{ERROR}), "The component exits with an error");
