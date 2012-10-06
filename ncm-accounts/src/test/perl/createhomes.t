#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use Carp qw(carp cluck);
use LC::File;
use subs qw(NCM::Component::accounts::mkdir NCM::Component::accounts::chown
	    NCM::Component::accounts::copy($$;%));
use NCM::Component::accounts;
use Test::MockModule;
use Readonly;

Readonly my $DIR => "target/test/homes";

our @chowned;

# Provide a fake chown function, just to be sure that our function is
# setting ownerships correctly
sub my_chown
{
    my ($owner, $group, $path) = @_;

    push(@chowned, [ $owner, $group, $path ]);
}

our (%created_dirs, %copied_files);

# Provide a fake makedir function, to control
sub my_makedir($;$)
{
    my ($dir, $mode) = @_;
    if (exists($created_dirs{$dir})) {
	$created_dirs{$dir}->{args} = [ $dir, $mode ];
	return $created_dirs{$dir}->{return};
    } else {
	$created_dirs{$dir} = { args => [ $dir, $mode ],
				return => 1 };
    }
    return 1;
}

# Provide a fake copy function
sub my_copy($$;%)
{
    my ($src, $dst, %opts) = @_;

    $copied_files{$src}->{$dst} = \%opts;
}

# Provide a sanitization argument that can trigger failures on demmand.
sub my_sanitize
{
    my ($self, $path) = @_;

    if (exists($self->{SHOULD_FAIL}->{$path})) {
	return undef;
    } else {
	return $path;
    }
}

my $mock = Test::MockModule->new('NCM::Component::accounts');
$mock->mock('makedir', \&my_makedir);
$mock->mock('copy', \&my_copy);
$mock->mock('chown', \&my_chown);
$mock->mock('sanitize_path', \&my_sanitize);


=pod

=head1 DESCRIPTION

Test how home directories are created

=head2 Tests

We test for successes and for failures.

=head3 Successess

The directory is created, it is locked before copy-ing anything into
it to prevent race conditions and symlink attacks, and finally, it is
restored.

=cut

sub ignore_lc_errors
{
    my ($ec, $e) = @_;

    $e->has_been_reported(1);
}

$NCM::Component::accounts::EC->error_handler(\&ignore_lc_errors
					    );

my $cmp = NCM::Component::accounts->new('accounts');

my $u = {
	 uid	    => 1,
	 main_group => 42,
	 homeDir    => "$DIR/foo",
	 name	    => "foo"
	};

$cmp->create_home('foo' => $u);

ok(exists($created_dirs{$u->{homeDir}}), "Directory was created properly");
is($cmp->{ERROR}, undef, "No errors generated in successful execution");
is($chowned[0]->[-1], $u->{homeDir}, "Directory is chowned immediately");
is($chowned[0]->[0], 0, "Directory is chowned to root");
is($chowned[-1]->[-1], $u->{homeDir}, "Directory has its ownership restored");
is($chowned[-1]->[0], $u->{uid}, "Directory has its ownership properly restored");

=head3 Errors

The directory couldn't be created. This either because:

=over

=item * The directory itself coudln't be created

That is, C<makedir> fails.

=cut

$created_dirs{$u->{homeDir}}->{return} = 0;
$cmp->create_home(foo => $u);
is($cmp->{ERROR}, 1, "Error in homeDir was detected and reported");

=pod

=item * The directory would have been created, but the main group was invalid

This may happen in the event of a bug.

=cut

delete($created_dirs{$u->{homeDir}});
$u->{main_group} = 'hello';

$cmp->create_home(foo => $u);
is($cmp->{ERROR}, 2, "Error in invalid GID was detected and reported");
ok(!exists($created_dirs{$u->{homeDir}}),
   "We don't try to build the directory with an invalid GID");

=pod

=item * The UID is invalid

Again, if we have some bug somewhere else. Shouldn't happen, but the
component is complex enough that it's worth protecting this method
against its own bugs.

=cut

$u->{main_group} = 42;
$u->{uid} = 'hello';

$cmp->create_home(foo => $u);
is($cmp->{ERROR}, 3, "Error in invalid UID was detected and reported");
ok(!exists($created_dirs{$u->{homeDir}}),
   "We don't try to build the directory with an invalid UID");

done_testing();
