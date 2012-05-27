#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::structured_config;
use CAF::Object;


$CAF::Object::NoAction = 1;


=pod

=head1 DESCRIPTION

Test how invalid/impossible Perl modules are handled.

=head1 TESTS

=cut


my $cmp = NCM::Component::structured_config->new('structured_config');

=pod

=head2 Invalid module names

Invalid module names must be reported and return an error

=cut

our $shouldnt_be_reached;

my $srv = { module => 'a;d' };
ok(!$cmp->handle_service("foo", $srv), "Invalid module name triggers an error");
ok(!$@, "Not even attempted to load an invalid module");
$srv->{module} = q{strict
	; $main::souldnt_be_reached = 1
      };
ok(!$cmp->handle_service("foo", $srv),
   "Malicious module name triggers an error");
is($shouldnt_be_reached, undef,
   "Sanitization prevented malicious code injection");
$srv->{module} = 'ljhljh';
ok(!$cmp->handle_service("foo", $srv),
   "Non-existing module raises an error");
ok($@, "Exception was risen on non-existing module");

=pod

=head2 Unsupported modules

Existing modules that don't support the expected interface are
rejected.

=cut

$cmp->{ERRORS} = 0;

$srv->{module} = 'File::Temp';
ok(!$cmp->handle_service('foo', $srv),
   "Existing but unsupported module is detected");

done_testing();
