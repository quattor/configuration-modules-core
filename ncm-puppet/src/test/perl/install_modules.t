# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Testing modules installation/upgrade

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

#1st Case: the module exists and it is installed.
# - upgrade function ok
# - install function is not invoked
# - no errors
#
set_desired_output("$UPGRADE INSTALLED_MODULE","stdout");
set_desired_err("$UPGRADE INSTALLED_MODULE","stderr");
set_command_status("$UPGRADE INSTALLED_MODULE",0);
set_desired_output("$INSTALL INSTALLED_MODULE","stdout");
set_desired_err("$INSTALL INSTALLED_MODULE","stderr");
set_command_status("$INSTALL INSTALLED_MODULE",0);

#2nd Case: the module exists and it is noy installed.
# - upgrade function fails
# - install function ok
# - no errors
#
set_desired_output("$UPGRADE NOT_INSTALLED_MODULE","stdout");
set_desired_err("$UPGRADE NOT_INSTALLED_MODULE","stderr");
set_command_status("$UPGRADE NOT_INSTALLED_MODULE",1<<8);
set_desired_output("$INSTALL NOT_INSTALLED_MODULE","stdout");
set_desired_err("$INSTALL NOT_INSTALLED_MODULE","stderr");
set_command_status("$INSTALL NOT_INSTALLED_MODULE",0);

#3rd Case: the module does not exist
# - upgrade function fails
# - install function fails
# - exit with errors
#
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
