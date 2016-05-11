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
Readonly my $COR => NCM::Component::spma::yum::YUM_CONF_CLEANUP_ON_REMOVE;
Readonly my $OBSOLETES => NCM::Component::spma::yum::YUM_CONF_OBSOLETES;
Readonly my $PLUGINCONFPATH => NCM::Component::spma::yum::YUM_CONF_PLUGINCONFPATH;
Readonly my $REPOSDIR => NCM::Component::spma::yum::YUM_CONF_REPOSDIR;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma::yum->new("spma");

my $extra_opts = {
    exclude => [qw(something else)],
    retries => 100,
};

=pod

=item * If they don't exist, it is appended.

=cut

set_file_contents($YUM_FILE, "a=1");
$cmp->configure_yum($YUM_FILE, 0, "/my/pluginpath", [qw(/dir/1 /dir/2)], $extra_opts);
my $fh = get_file($YUM_FILE);
like("$fh", qr{a=1\n$COR=1}, "Correct expansion");
like("$fh", qr{^$OBSOLETES=0$}m, "Obsoletes is expanded properly");
like("$fh", qr{^$PLUGINCONFPATH=/my/pluginpath$}m, "Pluginconfpath is expanded properly");
like("$fh", qr{^$REPOSDIR=/dir/1,/dir/2}m, "Reposdir is expanded properly");
# extra_opts
like("$fh", qr{^exclude=something else}m, "exclude is addedd properly (space separated)");
like("$fh", qr{^retries=100}m, "reries is added");

=pod

=item * If it exists but has wrong value, it is modified

=cut

set_file_contents($YUM_FILE, "$COR=fubar");
$cmp->configure_yum($YUM_FILE, 0, "/my/pluginpath", [qw(/dir/1 /dir/2)]);
$fh = get_file($YUM_FILE);
like("$fh", qr{^$COR=1$}m, "Correct substitution");

=pod

=item * If it exists and is correct, nothing happens

=cut

set_file_contents($YUM_FILE, "$COR=1\n$OBSOLETES=0\n$PLUGINCONFPATH=/my/pluginpath\n$REPOSDIR=/dir/1,/dir/2\nsomething=else");
$cmp->configure_yum($YUM_FILE, 0, "/my/pluginpath", [qw(/dir/1 /dir/2)]);
$fh = get_file($YUM_FILE);
is("$fh",
   "$COR=1\n$OBSOLETES=0\n$PLUGINCONFPATH=/my/pluginpath\n$REPOSDIR=/dir/1,/dir/2\nsomething=else",
   "The method is idempotent");

=pod

=item * Handle special characters

=cut

# existing /dir/123 value would match to be replaced /dir/1.3 if not properly escaped
set_file_contents($YUM_FILE, "$COR=1\n$OBSOLETES=0\n$PLUGINCONFPATH=/my/pluginpath\n$REPOSDIR=/dir/123,/dir/2\nsomething=else");
$cmp->configure_yum($YUM_FILE, 0, "/my/pluginpath", [qw(/dir/1.3 /dir/2)]);
$fh = get_file($YUM_FILE);
is("$fh",
   "$COR=1\n$OBSOLETES=0\n$PLUGINCONFPATH=/my/pluginpath\n\n$REPOSDIR=/dir/1.3,/dir/2\nsomething=else",
   "The method uses escaped regexp values; line is replaced");


done_testing();
