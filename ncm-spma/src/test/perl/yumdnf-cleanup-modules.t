# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the cleanup_old_dnf_modules method.  This method ensures that
outdated repositories in /etc/dnf/modules.d are removed.

As code largely reuses the cleanup_old_repos code (which is tested in yum-cleanup-repos,
testing here is limited somewhat.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use English;

use Test::Quattor;
use Test::More;
use NCM::Component::spma::yumdnf;

use File::Path qw(mkpath rmtree);
use LC::File;

Readonly my $MODULES_DIR => "target/test/clean.modules.d";

sub initialize_modules
{
    mkpath($MODULES_DIR);
    open(FH, ">", "$MODULES_DIR/mod1.module");
    open(FH, ">", "$MODULES_DIR/mod2.module");
}

my $cmp = NCM::Component::spma::yumdnf->new("spma");

=pod

=head2 The repository directory doesn't exist

If the repository directory doesn't exist, the error should be
reported.

=cut

rmtree($MODULES_DIR);

is($cmp->cleanup_old_dnf_modules($MODULES_DIR), 0, "Non-existing modules dir causes an error");
is($cmp->{ERROR}, 1, "Non-existing modules dir is reported to the user");

=pod

=head2 The modules dir exists and contains files that should be removed

In this case, any unwanted files should be removed

=cut

initialize_modules();

my $modules = {'mod1' => {}};

is($cmp->cleanup_old_dnf_modules($MODULES_DIR, $modules), 1, "Removal of files succeeds");
ok(!-e "$MODULES_DIR/mod2.module", "Unwanted module scheduled for removal");
ok(-e "$MODULES_DIR/mod1.module", "Wanted file not marked for deletion");

done_testing();
