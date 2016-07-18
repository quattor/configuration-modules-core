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

Readonly my $CONFIG_PREFIX => '/software/components/afsclt';

my $comp;

sub get_config_tree {
    my $profile = shift;

    my $config = get_config_for_profile($profile);
    return $config->getElement($CONFIG_PREFIX)->getTree();
}


# Standard test:
#    - Execute configuration method
#    - Check that the configuration file exists
#    - Open it
#    - Check its contents against a reference contents
sub execute_standard_test {
    my ($file, $expected_contents, $config, $msg) = @_;

    my $status = $comp->Configure_TheseCells($config);
    ok(!$status, "Configure_TheseCells returned no explicit error");
    my $fh = get_file($file);
    ok(defined($fh), $file." was opened ($msg)");
    is("$fh", $expected_contents, $file." has expected contents ($msg)");
    $fh->close();
}


#############
# Main code #
#############

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

$comp = NCM::Component::afsclt->new('afsclt');

my $config_thesecells = get_config_tree("explicit");
my $config_no_thesecells = get_config_tree("automatic");

# Initial TheseCells doesn't exist
execute_standard_test($THESECELLS_FILE, $THESECELLS_EXPECTED, $config_thesecells, "initially not existing");

# Initial TheseCells content different from expected one
set_file_contents($THESECELLS_FILE,"abcdefg");
execute_standard_test($THESECELLS_FILE, $THESECELLS_EXPECTED, $config_thesecells, "initial content wrong");

# Initial TheseCells content matching expected one
set_file_contents($THESECELLS_FILE,$THESECELLS_EXPECTED);
execute_standard_test($THESECELLS_FILE, $THESECELLS_EXPECTED, $config_thesecells, "initial content ok");

# TheseCells file exists but configuration doesn't contain thesecells information
set_file_contents($THESECELLS_FILE,$THESECELLS_EXPECTED);
my $status = $comp->Configure_TheseCells($config_no_thesecells);
ok(!$status, "Configure_TheseCells returned no explicit error");
my $fh = get_file($THESECELLS_FILE);
ok(defined(!$fh), $THESECELLS_FILE." removed");


Test::NoWarnings::had_no_warnings();

