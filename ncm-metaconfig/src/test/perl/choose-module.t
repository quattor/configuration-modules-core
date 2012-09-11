#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::metaconfig;
use CAF::Object;


$CAF::Object::NoAction = 1;


=pod

=head1 DESCRIPTION

Test how invalid/impossible Perl modules are handled.

=head1 TESTS

=cut

no warnings 'redefine';

*NCM::Component::metaconfig::tt = sub {
    my ($self, @args) = @_;
    $self->{tt}++;
    return 1;
};

use warnings 'redefine';

my $cmp = NCM::Component::metaconfig->new('metaconfig');

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

=pod

=head2 Defaulting to Template::Toolkit

By default the C<tt> method is invoked

=cut

$cmp->{ERRORS} = 0;

$srv->{module} = 'foo/bar';
ok($cmp->handle_service('foo', $srv),
   "Services may fall safely to the template toolkit");
is($cmp->{tt}, 1, "Unknown modules fall back to the template toolkit");

done_testing();
