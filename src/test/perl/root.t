#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor; # qw(root/basic);
use NCM::Component::accounts;

=pod

=head1 DESCRIPTION

Test how the root account is set

=cut

my $cmp = NCM::Component::accounts->new('accounts');

# System's root user mockup
my $sys = { passwd => { root => {
				 groups => [ qw(g1 g2 g3) ],
				 shell => 'invalid root shell',
				 homeDir => '/home/for/root',
				 ln => 42
			       }
		      }
	  };
# Profile mockup for the root user
my $pfr = {
	  };

my $root = $cmp->compute_root_user($sys, $pfr);

is($root->{uid}, 0, "New root user has the correct UID");

for my $i (0..scalar(@{$sys->{passwd}->{root}->{groups}})) {
    is($root->{groups}->[$i], $sys->{passwd}->{root}->{groups}->[$i],
       "Root groups inherited correctly from the system");
}

is($root->{password}, "!", "Root account with no passwords is blocked");
is($root->{shell}, undef, "Root shell is not inherited from system");
is($root->{ln}, 42, "Root will be written in the same old line in the file");

$sys->{passwd}->{root}->{password} = "An old password";
$root = $cmp->compute_root_user($sys, $pfr);
is($root->{password}, $sys->{passwd}->{root}->{password},
   "Root inherits the password from the system, when present");
$pfr->{rootpwd} = "A new password";
$pfr->{rootshell} = "A valid root shell";
$root = $cmp->compute_root_user($sys, $pfr);
is($root->{shell}, $pfr->{rootshell},
   "Root receives its shell only from the profile");
is($root->{password}, $pfr->{rootpwd},
   "Profile's root password takes priority over system's old password");

done_testing();
