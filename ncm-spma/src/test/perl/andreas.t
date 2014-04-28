#!/usr/bin/perl
# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<update_pkgs> method, looking for a bug reported by
Andreas Nowack.

The problem seemed to be that we over-optimized.  When the transaction
was expected to be empty, Yum wouldn't get called.

However, there may be pending updates, or versions of already
installed packages may have changed.  And we need Yum to figure this
out on our behalf.

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use CAF::Object;
use Readonly;

Readonly my $RPMQ => join(" ", @{NCM::Component::spma::yum::RPM_QUERY()});
Readonly my $DISTROSYNC => join(" ", NCM::Component::spma::yum::YUM_DISTRO_SYNC);
Readonly my $YUMEXPIRE => join(" ", NCM::Component::spma::yum::YUM_EXPIRE);
Readonly my $REPOQ => join(" ", NCM::Component::spma::yum::REPOQUERY,
			   "ncm-cdp-1.0.4-1.noarch");
Readonly my $YUMCT => join(" ", NCM::Component::spma::yum::YUM_COMPLETE_TRANSACTION);
Readonly my $LEAF => join(" ", @{NCM::Component::spma::yum::LEAF_PACKAGES()});

set_desired_output($RPMQ, "ncm-cdp;noarch\n");
set_desired_err($DISTROSYNC, "");
set_desired_output($DISTROSYNC, "");
set_desired_err($YUMEXPIRE, "");
set_desired_output($YUMEXPIRE, "");
set_desired_err($REPOQ, "");
set_desired_output($REPOQ, "0:ncm-cdp-1.0.4-1.noarch\n");
set_desired_err($YUMCT, "");
set_desired_output($YUMCT, "");
set_desired_output($LEAF, "");

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma::yum->new("spma");

# A list of packages, based on a real profile.
my $wanted = {
	  "ncm_2dcdp" => {
		  "_31_2e0_2e4_2d1" => { arch => { noarch => '' }}}};

$cmp->update_pkgs($wanted, {}, 1, 0);

my $cmd = get_command($DISTROSYNC);
ok(defined($cmd), "Command is truly called");

done_testing();
