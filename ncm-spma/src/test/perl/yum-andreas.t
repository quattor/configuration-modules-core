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

Readonly::Array my @RPM_QUERY_ORIG => @{NCM::Component::spma::yum::RPM_QUERY()};
Readonly::Array my @RPM_QUERY => @{NCM::Component::spma::yum::_set_yum_config(\@RPM_QUERY_ORIG)};
Readonly my $RPMQ => join(" ", @RPM_QUERY);

Readonly::Array my @YDS_ORIG => NCM::Component::spma::yum::YUM_DISTRO_SYNC();
Readonly::Array my @YDS => @{NCM::Component::spma::yum::_set_yum_config(\@YDS_ORIG)};
Readonly my $DISTROSYNC => join(" ", @YDS);

Readonly::Array my @YE_ORIG => NCM::Component::spma::yum::YUM_EXPIRE();
Readonly::Array my @YE => @{NCM::Component::spma::yum::_set_yum_config(\@YE_ORIG)};
Readonly my $YUMEXPIRE => join(" ", @YE);

Readonly::Array my @MC_ORIG => NCM::Component::spma::yum::YUM_MAKECACHE();
Readonly::Array my @MC => @{NCM::Component::spma::yum::_set_yum_config(\@MC_ORIG)};
Readonly my $MAKECACHE => join(" ", @MC);

Readonly::Array my @REPOQUERY_ORIG => NCM::Component::spma::yum::REPOQUERY();
Readonly::Array my @REPOQUERY => @{NCM::Component::spma::yum::_set_yum_config(\@REPOQUERY_ORIG)};
Readonly my $REPOQ => join(" ", @REPOQUERY, "ncm-cdp-1.0.4-1.noarch");

Readonly::Array my @YCT_ORIG => NCM::Component::spma::yum::YUM_COMPLETE_TRANSACTION();
Readonly::Array my @YCT => @{NCM::Component::spma::yum::_set_yum_config(\@YCT_ORIG)};
Readonly my $YUMCT => join(" ", @YCT);

Readonly::Array my @LP_ORIG => @{NCM::Component::spma::yum::LEAF_PACKAGES()};
Readonly::Array my @LP => @{NCM::Component::spma::yum::_set_yum_config(\@LP_ORIG)};
Readonly my $LEAF => join(" ", @LP);

set_desired_output($RPMQ, "ncm-cdp;noarch\n");
set_desired_err($DISTROSYNC, "");
set_desired_output($DISTROSYNC, "");
set_desired_err($YUMEXPIRE, "");
set_desired_output($YUMEXPIRE, "");
set_desired_err($MAKECACHE, "");
set_desired_output($MAKECACHE, "");
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
