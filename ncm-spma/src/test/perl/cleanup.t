# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<configure_yum> method.  This method modifies the
yum.conf file to ensure it has the C<clean_requirements_on_remove>
flag before starting, and the C<obsolete> is set to the expected value.

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
use NCM::Component::spma::yum;
use CAF::Object;


Readonly my $YUM_FILE => "target/test/cleanup.conf";
Readonly my $FIELD => NCM::Component::spma::yum::CLEANUP_ON_REMOVE;
Readonly my $OBSOLETE => NCM::Component::spma::yum::OBSOLETE;



$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma::yum->new("spma");

=pod

=item * If they don't exist, it is appended.

=cut

set_file_contents($YUM_FILE, "a=1");
$cmp->configure_yum($YUM_FILE, 0);
my $fh = get_file($YUM_FILE);
like("$fh", qr{a=1\n$FIELD=1}, "Correct expansion");
like("$fh", qr{^$OBSOLETE=0$}m, "Obsolete is expanded properly");

=pod

=item * If it exists but has wrong value, it is modified

=cut

set_file_contents($YUM_FILE, "$FIELD=fubar");
$cmp->configure_yum($YUM_FILE, 0);
$fh = get_file($YUM_FILE);
like("$fh", qr{^$FIELD=1$}m, "Correct substitution");

=pod

=item * If it exists and is correct, nothing happens

=cut

set_file_contents($YUM_FILE, "$FIELD=1\n$OBSOLETE=0");
$cmp->configure_yum($YUM_FILE, 0);
$fh = get_file($YUM_FILE);
is("$fh", "$FIELD=1\n$OBSOLETE=0", "The method is idempotent");

=pod

=item *

=cut

done_testing();
