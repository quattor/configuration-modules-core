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
use NCM::Component::spma::yum;
use Test::MockObject::Extends;
use CAF::Object;
use Set::Scalar;
use Class::Inspector;
use Carp qw(confess);

Readonly my $UPDATE_PKGS => -1;
Readonly my $GENERATE_REPOS => 3;

$SIG{__DIE__} = 'DEFAULT';


my @funcs = grep(m{^[a-z]} && $_ ne 'unescape',
		 @{Class::Inspector->functions("NCM::Component::spma::yum")});

my $cmp = NCM::Component::spma::yum->new("spma");
my $mock = Test::MockObject::Extends->new($cmp);

$mock->set_true(@funcs);

$CAF::Object::NoAction = 1;


my $cfg = get_config_for_profile("simple");
my $repos = $cfg->getElement("/software/repositories")->getTree();
my $pkgs = $cfg->getElement("/software/packages")->getTree();
my %calls;

is($cmp->Configure($cfg), 1, "Simple configuration succeeds");

=pod

=head2 Simple profile

We use the simplest profile for this, which doesn't allow for user
packages and enforces the execution of the transaction. We test for:

=head3 Correct flow

All the top-level methods are called, with C<update_pkgs> being the last one.

=cut


my $name = $mock->call_pos($UPDATE_PKGS);
is($name, "update_pkgs", "Packages are updated at the end of the component");
my @args = $mock->call_args($UPDATE_PKGS);
is(ref($args[2]), 'HASH', "Set of groups is passed");
ok($args[3], "Run argument is correctly passed");
ok(!$args[4], "No user packages allowed in update_pkgs");
ok(exists($args[1]->{ConsoleKit}),
  "A package list is passed to UPDATE_PKGS");

=pod

=head3 Correct arguments to each callee

=cut

while (my ($name, $args) = $mock->next_call()) {
    $calls{$name} = $args;
}


=over

=item * C<initialize_repos_dir>

=cut

is($calls{initialize_repos_dir}->[1], "/etc/yum.repos.d",
   "Correct Yum repository directory initialized");

=pod

=item * C<cleanup_old_repos>

=cut

@args = @{$calls{cleanup_old_repos}};

is($args[1], "/etc/yum.repos.d",
   "Correct Yum repository directory to be cleaned up");
is(ref($args[2]), 'ARRAY',
   'A list with repositories is passed to clean up non-existing repos');
is($args[2]->[0]->{name}, $repos->[0]->{name},
   "The profile's list of repositories is passed to cleanup_old_repos");
ok(!$args[3], "No user repositories allowed");

=pod

=item * C<generate_repos>

=cut

@args = @{$calls{generate_repos}};
is($args[1], "/etc/yum.repos.d",
   "Correct Yum repository directory to be initialised");
is(ref($args[2]), 'ARRAY',
   "A list of repositories is passed to generate_repos");
is($args[2]->[0]->{name}, $repos->[0]->{name},
   "The profile's list of repositories is passed to generate_repos");
like($args[3], qr{spma/.*repo.*tt$},
     "Correct repository template passed");
ok(!$args[4], "No proxy passed to generate_repos");

=pod

=head2 Proxy settings

These must show up when calling C<generate_repos>

=cut

$cfg = get_config_for_profile("with_proxy");

my $t = $cfg->getElement("/software/components/spma")->getTree();

$mock->clear();

is($cmp->Configure($cfg), 1, "Proxy settings don't affect the outcome");

@args = $mock->call_args($GENERATE_REPOS);

is($args[-3], $t->{proxyhost}, "Correct proxy host passed to generate_repos");
is($args[-2], $t->{proxytype}, "Correct proxy type passed to generate_repos");
is($args[-1], $t->{proxyport}, "Correct proxy port passed to generate_repos");

=pod

=head2 SPMA disabled

It must show up when calling C<update_pkgs>

=cut

$cfg = get_config_for_profile("without_spma");

$mock->clear();

$cmp->Configure($cfg);
@args = $mock->call_args($UPDATE_PKGS);
ok(!$args[3], "No run is correctly passed to update_pkgs");

=pod

=head2 User packages allowed

They show up in C<cleanup_old_repos> and C<update_pkgs>

=cut

$cfg = get_config_for_profile("with_pkgs");

$mock->clear();

$cmp->Configure($cfg);

while (my ($n, $a) = $mock->next_call()) {
    if ($n eq 'update_pkgs' || $n eq 'cleanup_old_repos') {
	ok($a->[3], "User packages are passed correctly to $name");
    }
}

=pod

=head2 Error handling

We also test that all errors in functions are correctly handled

=over

=item * The update of packages fails

We expect an error code to be returned.

=cut

$mock->clear();
$mock->set_false('update_pkgs');


is($cmp->Configure($cfg), 0, "Failure in update_pkgs is propagated");
$mock->called_ok('update_pkgs', "update_pkgs is called");

=pod

=item * Any other method fails

The error is propagated, and C<update_pkgs> is never called

=cut


foreach my $f (qw(generate_repos cleanup_old_repos initialize_repos_dir)) {
    $mock->clear();
    $mock->set_false($f);
    is($cmp->Configure($cfg), 0, "Failure in $f is propagated");
    ok(!$mock->called('update_pkgs'));
    $mock->set_true($f);
}

=pod

=item * The LANG environment variable is kept

=cut

$mock->mock('generate_repos', sub {
		    is($ENV{LANG}, "C", "LANG environment variable kept");
		    return 1;
	    });

done_testing();

__END__

=pod

=back

=cut
