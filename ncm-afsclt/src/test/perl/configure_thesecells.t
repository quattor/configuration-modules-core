# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;

use Test::More tests => 13;
use Test::NoWarnings;
use Test::Quattor qw(automatic explicit);
use NCM::Component::afsclt;
use Readonly;
use CAF::Object;
Test::NoWarnings::clear_warnings();

=pod

=head1 SYNOPSIS

Tests for AFS TheseCells configuration

=cut

Readonly my $THESECELLS_FILE => '/usr/vice/etc/TheseCells';
Readonly my $THESECELLS_EXPECTED => 'cern.ch morganstanley.com
';

#############
# Main code #
#############


my $fh;
my $status;

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

my $comp = NCM::Component::afsclt->new('afsclt');

my $config_thesecells = get_config_for_profile("explicit");
my $config_no_thesecells = get_config_for_profile("automatic");

# Initial TheseCells doesn't exist
$status = $comp->Configure_TheseCells($config_thesecells);
ok(!$status, "Configure_TheseCells returned no explicit error");
$fh = get_file($THESECELLS_FILE);
ok(defined($fh), $THESECELLS_FILE." was opened");
is("$fh", $THESECELLS_EXPECTED, $THESECELLS_FILE." (initially not existing) has expected contents");
$fh->close();

# Initial TheseCells content different from expected one
set_file_contents($THESECELLS_FILE,"abcdefg");
$status = $comp->Configure_TheseCells($config_thesecells);
ok(!$status, "Configure_TheseCells returned no explicit error");
$fh = get_file($THESECELLS_FILE);
ok(defined($fh), $THESECELLS_FILE." was opened");
is("$fh", $THESECELLS_EXPECTED, $THESECELLS_FILE." (initial content wrong) has expected contents");
$fh->close();

# Initial TheseCells content matching expected one
set_file_contents($THESECELLS_FILE,$THESECELLS_EXPECTED);
$status = $comp->Configure_TheseCells($config_thesecells);
ok(!$status, "Configure_TheseCells returned no explicit error");
$fh = get_file($THESECELLS_FILE);
ok(defined($fh), $THESECELLS_FILE." was opened");
is("$fh", $THESECELLS_EXPECTED, $THESECELLS_FILE." (initial content ok) has expected contents");
$fh->close();

# TheseCells file exists but configuration doesn't contain thesecells information
set_file_contents($THESECELLS_FILE,$THESECELLS_EXPECTED);
$status = $comp->Configure_TheseCells($config_no_thesecells);
ok(!$status, "Configure_TheseCells returned no explicit error");
$fh = get_file($THESECELLS_FILE);
ok(defined(!$fh), $THESECELLS_FILE." removed");


Test::NoWarnings::had_no_warnings();

