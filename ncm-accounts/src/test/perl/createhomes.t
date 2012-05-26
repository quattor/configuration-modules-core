#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::accounts;
use File::Temp qw(tempdir);
use Carp qw(carp cluck);


our @chowned;

=pod

=head1 DESCRIPTION

Test how home directories are created

For now, this is a very limited test. It only ensures the home dir is
created, and the files in /etc/skel are copied. It doesn't guarantee
the security of the process, since that's pretty difficult to test
without privileges.

=cut

my $dir = tempdir(CLEANUP => 1);

sub ignore_lc_errors
{
    my ($ec, $e) = @_;

    $e->has_been_reported(1);
}


no warnings 'redefine';
*LC::Fatal::chown = sub ($$@) {
    push(@chowned, \@_);
};
use warnings 'redefine';

$NCM::Component::accounts::EC->error_handler(\&ignore_lc_errors
					    );

my $cmp = NCM::Component::accounts->new('accounts');

my $u = {
	 uid	    => 1,
	 main_group => 42,
	 homeDir    => "$dir/foo",
	 name	    => "foo"
	};

$cmp->create_home('foo' => $u);
ok(-d $u->{homeDir}, "Directory was truly created");
ok(glob("$u->{homeDir}/.*"), "/etc/skel was copied to the home dir");


done_testing();
