# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<configure_yum> method.  This method modifies the
yum.conf file to ensure it has the C<clean_requirements_on_remove>
flag before starting.

=head1 TESTS

We need to ensure that the line C<clean_requirements_on_remove> exists
and is set to 1. So,

=over

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma;
use CAF::Object;


Readonly my $YUM_FILE => "target/test/cleanup.conf";
Readonly my $FIELD => NCM::Component::spma::CLEANUP_ON_REMOVE;




$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma->new("spma");

=pod

=item * If it doesn't exist, it is appended.

=cut

set_file_contents($YUM_FILE, "a=1");
$cmp->configure_yum($YUM_FILE);
my $fh = get_file($YUM_FILE);
is("$fh", "a=1\n$FIELD=1\n", "Correct expansion");

=pod

=item * If it exists but has wrong value, it is modified

=cut

set_file_contents($YUM_FILE, "$FIELD=fubar");
$cmp->configure_yum($YUM_FILE);
$fh = get_file($YUM_FILE);
is("$fh", "\n$FIELD=1\n", "Correct substitution");

=pod

=item * If it exists and is correct, nothing happens

=cut

set_file_contents($YUM_FILE, "$FIELD=1");
$cmp->configure_yum($YUM_FILE);
$fh = get_file($YUM_FILE);
is("$fh", "$FIELD=1", "The method is idempotent");

done_testing();
