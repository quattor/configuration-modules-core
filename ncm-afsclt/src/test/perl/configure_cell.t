# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;

use Test::More tests => 11;
use Test::NoWarnings;
use Test::Quattor qw(explicit);
use NCM::Component::afsclt;
use Readonly;
use CAF::Object;
Test::NoWarnings::clear_warnings();

=pod

=head1 SYNOPSIS

Tests for AFS cell configuration

=cut

Readonly my $THISCELL_FILE => '/usr/vice/etc/ThisCell';
Readonly my $THISCELL_EXPECTED => 'in2p3.fr
';

Readonly my $CONFIG_PREFIX => '/software/components/afsclt';


sub get_config_tree {
    my $profile = shift;

    my $config = get_config_for_profile($profile);
    return $config->getElement($CONFIG_PREFIX)->getTree();
}


#############
# Main code #
#############


my $fh;
my $status;

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

my $comp = NCM::Component::afsclt->new('afsclt');

my $config_explicit = get_config_tree("explicit");

# Initial ThisCell file empty
set_file_contents($THISCELL_FILE,"");
$status = $comp->Configure_Cell($config_explicit);
ok(!$status, "Configure_Cell returned no explicit error");
$fh = get_file($THISCELL_FILE);
ok(defined($fh), $THISCELL_FILE." was opened");
is("$fh", $THISCELL_EXPECTED, $THISCELL_FILE." (initially empty) has expected contents");
$fh->close();

# Initial ThisCell content different from expected one
set_file_contents($THISCELL_FILE,"abcdefg");
$status = $comp->Configure_Cell($config_explicit);
ok(!$status, "Configure_Cell returned no explicit error");
$fh = get_file($THISCELL_FILE);
ok(defined($fh), $THISCELL_FILE." was opened");
is("$fh", $THISCELL_EXPECTED, $THISCELL_FILE." (initial content wrong) has expected contents");
$fh->close();

# Initial ThisCell content matching expected one
set_file_contents($THISCELL_FILE,$THISCELL_EXPECTED);
$status = $comp->Configure_Cell($config_explicit);
ok(!$status, "Configure_Cell returned no explicit error");
$fh = get_file($THISCELL_FILE);
ok(defined($fh), $THISCELL_FILE." was opened");
is("$fh", $THISCELL_EXPECTED, $THISCELL_FILE." (initial content ok) has expected contents");
$fh->close();

Test::NoWarnings::had_no_warnings();

