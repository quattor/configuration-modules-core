#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::metaconfig;
use CAF::FileWriter;
use File::Path qw(mkpath);
use Cwd qw(abs_path);
use Carp qw(confess);

eval {use Template};
plan skip_all => "Template::Toolkit not found" if $@;

use Readonly;

Readonly my $TEMPLATE => "metaconfig/foo.tt";

=pod

=head1 DESCRIPTION

Test that a template specified by Template::Toolkit is an existing
file in the metaconfig template directory. This is crucial for the
security of the component.

=head1 TESTS

=head2 Error conditions

It's here where the security of the component (and all its users) is
dealt with. After this, the component is allowed to trust all its
inputs.

=over 4

=cut

my $cmp = NCM::Component::metaconfig->new('metaconfig');

Readonly my $DIR => $cmp->template()->service()->context()->config()->{INCLUDE_PATH};

mkpath($DIR);


diag($cmp->template()->service()->context()->config()->{INCLUDE_PATH});

$cmp->template()->service()->context()->config()->{INCLUDE_PATH} = abs_path($DIR);

=pod

=item * Absolute paths must be rejected

Otherwise, we might leak files like /etc/shadow or private keys.

=cut

ok(!$cmp->sanitize_template("/etc/shadow"), "Absolute paths are rejected");
is($cmp->{ERROR}, 1, "Error is reported");

=pod

=item * Non-existing files must be rejected

They may abuse File::Spec.

=cut

ok(!$cmp->sanitize_template("lhljkhljhlh789ggl"),
   "Non-existing filenames are rejected");
is($cmp->{ERROR}, 2, "Non-existing templates are rejected");

=pod

=item * Templates must end up under C<<template-path>/metaconfig>

Templates in this component are jailed to that directory, again to
prevent cross-directory traversals.

=back

=cut


my $fh = CAF::FileWriter->new("$DIR/$TEMPLATE");
print $fh "Test content";
$fh->close();

ok(!$cmp->sanitize_template("../"),
   "It's not possible to leave the 'metaconfig' jail");

=pod

=head2 Successful executions

=cut

is($cmp->sanitize_template("foo.tt"), $TEMPLATE,
   "Valid template is accepted");

is($cmp->sanitize_template("foo"), $TEMPLATE,
   "Valid template may have an extension added to it");



done_testing();
