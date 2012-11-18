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

=pod

=head1 TEST TYPES

=head2 Almost empty system, no specification in the profile

Root account should be blocked, but root groups are always read from
the system.

=cut


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


is(shift(@{$root->{groups}}), 'root', "Root always gets added to the root group");

for my $i (0..scalar(@{$sys->{passwd}->{root}->{groups}})) {
    is($root->{groups}->[$i], $sys->{passwd}->{root}->{groups}->[$i],
       "Root groups inherited correctly from the system");
}

is($root->{password}, "!", "Root account with no passwords is blocked");
is($root->{shell}, $sys->{passwd}->{root}->{shell},
   "Root shell is inherited from system");
is($root->{ln}, 42, "Root will be written in the same old line in the file");

delete($sys->{passwd}->{root}->{shell});
$root = $cmp->compute_root_user($sys, $pfr);
is($root->{shell}, "/bin/bash",
   "Root shell set to bash when not available in the profile or the system");

=pod

=head2 Inheriting settings from system

When the profile doesn't state otherwise, password is inherited from
the system. However, the shell isn't.

=cut

$sys->{passwd}->{root}->{password} = "An old password";
$root = $cmp->compute_root_user($sys, $pfr);
is($root->{password}, $sys->{passwd}->{root}->{password},
   "Root inherits the password from the system, when present");
$pfr->{rootpwd} = "A new password";
$pfr->{rootshell} = "A valid root shell";

=pod

=head2 Overriding ancient values with profile-provided ones

=cut

$root = $cmp->compute_root_user($sys, $pfr);

is($root->{shell}, $pfr->{rootshell},
   "Root receives its shell only from the profile");
is($root->{password}, $pfr->{rootpwd},
   "Profile's root password takes priority over system's old password");

delete($sys->{passwd}->{root}->{groups});
$root = $cmp->compute_root_user($sys, $pfr);
ok(exists($root->{groups}), "Root gets a default set of groups when none exist");
is($root->{groups}->[0], "root", "Default group list starts with root");
$sys->{passwd}->{root}->{groups} = [];
$root = $cmp->compute_root_user($sys, $pfr);
ok(exists($root->{groups}),
   "Root gets a default set of groups when the system list is empty");
is($root->{groups}->[0], "root", "Default group list starts with root");

done_testing();
