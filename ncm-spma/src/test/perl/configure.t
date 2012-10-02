# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<Configure> method.  This method should just call a few
others, and return successes or failures as needed.

=head1 TESTS

We test that the correct methods are called, and their arguments.

=cut

BEGIN {
    use Carp qw(confess);
}

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor qw(simple with_proxy without_spma with_pkgs);
use NCM::Component::spma;
use CAF::Object;
use Set::Scalar;
use Class::Inspector;

my @funcs = grep(m{^[a-z]} && $_ ne 'unescape',
		 @{Class::Inspector->functions("NCM::Component::spma")});

no warnings 'redefine';
no strict 'refs';

my $call_order = 0;

foreach my $f (@funcs) {
    *{"NCM::Component::spma::$f"} = sub {
	my ($self, @args) = @_;
	$self->{uc($f)}->{called} = ++$call_order;
	$self->{uc($f)}->{args} = \@args;
	return $self->{uc($f)}->{return} // 1;
    };
};

use warnings 'redefine';
use strict 'refs';

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma->new("spma");

my $cfg = get_config_for_profile("simple");
my $repos = $cfg->getElement("/software/repositories")->getTree();
my $pkgs = $cfg->getElement("/software/packages")->getTree();

is($cmp->Configure($cfg), 1, "Simple configuration succeeds");

=pod

=head2 Simple profile

We use the simplest profile for this, which doesn't allow for user
packages and enforces the execution of the transaction. We test for:

=head3 Correct flow

All the top-level methods are called, with C<update_pkgs> being the last one.

=cut

foreach my $f (map(uc($_), @funcs)) {
    next if $f eq "UPDATE_PKGS";
    if (exists($cmp->{$f})) {
	ok($cmp->{$f}->{called} < $cmp->{UPDATE_PKGS}->{called},
	   "Method $f called before UPDATE_PKGS");
    }
}

=pod

=head3 Correct arguments to each callee

=over

=item * C<initialize_repos_dir>

=cut

is($cmp->{INITIALIZE_REPOS_DIR}->{args}->[0], "/etc/yum.repos.d",
   "Correct Yum repository directory initialized");

=pod

=item * C<cleanup_old_repos>

=cut


is($cmp->{CLEANUP_OLD_REPOS}->{args}->[0], "/etc/yum.repos.d",
   "Correct Yum repository directory to be cleaned up");
is(ref($cmp->{CLEANUP_OLD_REPOS}->{args}->[1]), 'ARRAY',
   'A list with repositories is passed to clean up non-existing repos');
is($cmp->{CLEANUP_OLD_REPOS}->{args}->[1]->[0]->{name}, $repos->[0]->{name},
   "The profile's list of repositories is passed to cleanup_old_repos");
ok(!$cmp->{CLEANUP_OLD_REPOS}->{args}->[2], "No user repositories allowed");

=pod

=item * C<generate_repos>

=cut

is($cmp->{GENERATE_REPOS}->{args}->[0], "/etc/yum.repos.d",
   "Correct Yum repository directory to be initialised");
is(ref($cmp->{GENERATE_REPOS}->{args}->[1]), 'ARRAY',
   "A list of repositories is passed to generate_repos");
is($cmp->{GENERATE_REPOS}->{args}->[1]->[0]->{name}, $repos->[0]->{name},
   "The profile's list of repositories is passed to generate_repos");
like($cmp->{GENERATE_REPOS}->{args}->[2], qr{spma/.*repo.*tt$},
     "Correct repository template passed");
ok(!$cmp->{GENERATE_REPOS}->{args}->[3], "No proxy passed to generate_repos");

=pod

=item * C<update_pkgs>

=back

=cut

ok(exists($cmp->{UPDATE_PKGS}->{args}->[0]->{ConsoleKit}),
   "A package list is passed to UPDATE_PKGS");
ok($cmp->{UPDATE_PKGS}->{args}->[1], "Run argument is correctly");
ok(!$cmp->{UPDATE_PKGS}->{args}->[2], "No user packages allowed in update_pkgs");

=pod

=head2 Proxy settings

These must show up when calling C<generate_repos>

=cut

$cfg = get_config_for_profile("with_proxy");

my $t = $cfg->getElement("/software/components/spma")->getTree();

is($cmp->Configure($cfg), 1, "Proxy settings don't affect the outcome");
is($cmp->{GENERATE_REPOS}->{args}->[3], $t->{proxyhost},
   "Correct proxy host passed to generate_repos");
is($cmp->{GENERATE_REPOS}->{args}->[4], $t->{proxytype},
   "Correct proxy type passed to generate_repos");
is($cmp->{GENERATE_REPOS}->{args}->[5], $t->{proxyport},
   "Correct proxy port passed to generate_repos");

=pod

=head2 SPMA disabled

It must show up when calling C<update_pkgs>

=cut

$cfg = get_config_for_profile("without_spma");

$cmp->Configure($cfg);
ok(!$cmp->{UPDATE_PKGS}->{args}->[1], "No run is correctly passed to update_pkgs");

=pod

=head2 User packages allowed

They show up in C<cleanup_old_repos> and C<update_pkgs>

=cut

$cfg = get_config_for_profile("with_pkgs");

$cmp->Configure($cfg);

ok($cmp->{UPDATE_PKGS}->{args}->[1],
   "User packages are passed correctly to update_pkgs");
ok($cmp->{CLEANUP_OLD_REPOS}->{args}->[2],
   "Userpackages are passed correctly to cleanup_old_repos");


=pod

=head2 Error handling

We also test that all errors in functions are correctly handled

=over

=item * The update of packages fails

We expect an error code to be returned.

=cut

$call_order = 0;
$cmp->{UPDATE_PKGS}->{return} = 0;
is($cmp->Configure($cfg), 0, "Failure in update_pkgs is propagated");
is($cmp->{UPDATE_PKGS}->{called}, $call_order,
   "update_pkgs is called during the first error test");
$cmp->{UPDATE_PKGS}->{called} = 0;

=pod

=item * Any other method fails

The error is propagated, and C<update_pkgs> is never called

=cut

foreach my $f (qw(generate_repos cleanup_old_repos initialize_repos_dir)) {
    $cmp->{uc($f)}->{return} = 0;
    is($cmp->Configure($cfg), 0, "Failure in $f is propagated");
    is($cmp->{UPDATE_PKGS}->{called}, 0,
       "update_pkgs is not called when a method $f fails");
    $cmp->{uc($f)}->{return} = 1;
}


done_testing();

__END__

=pod

=back
