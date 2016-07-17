# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;

use Test::More tests => 17;
use Test::NoWarnings;
use Test::Quattor qw(automatic automatic_nocachemount explicit);
use NCM::Component::afsclt;
use Readonly;
use CAF::Object;
Test::NoWarnings::clear_warnings();

=pod

=head1 SYNOPSIS

Tests for AFS afsd_args configuration

=cut

Readonly my $AFSD_ARGS_FILE => '/etc/afsd.args';
Readonly my $AFSD_ARGS_EXPECTED => 'daemons:2
files:100
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

my $config_afsd_args = get_config_tree("explicit");
my $config_empty_afsd_args = get_config_tree("automatic_nocachemount");
my $config_no_afsd_args = get_config_tree("automatic");

# Initial afsd.args doesn't exist
$status = $comp->Configure_Afsd_Args($config_afsd_args);
ok(!$status, "Configure_Afsd_Args returned no explicit error");
$fh = get_file($AFSD_ARGS_FILE);
ok(defined($fh), $AFSD_ARGS_FILE." was opened");
is("$fh", $AFSD_ARGS_EXPECTED, $AFSD_ARGS_FILE." (initially not existing) has expected contents");
$fh->close();

# Initial afsd.args content different from expected one
set_file_contents($AFSD_ARGS_FILE,"abcdefg");
$status = $comp->Configure_Afsd_Args($config_afsd_args);
ok(!$status, "Configure_Afsd_Args returned no explicit error");
$fh = get_file($AFSD_ARGS_FILE);
ok(defined($fh), $AFSD_ARGS_FILE." was opened");
is("$fh", $AFSD_ARGS_EXPECTED, $AFSD_ARGS_FILE." (initial content wrong) has expected contents");
$fh->close();

# Initial afsd.args content matching expected one
set_file_contents($AFSD_ARGS_FILE,$AFSD_ARGS_EXPECTED);
$status = $comp->Configure_Afsd_Args($config_afsd_args);
ok(!$status, "Configure_Afsd_Args returned no explicit error");
$fh = get_file($AFSD_ARGS_FILE);
ok(defined($fh), $AFSD_ARGS_FILE." was opened");
is("$fh", $AFSD_ARGS_EXPECTED, $AFSD_ARGS_FILE." (initial content ok) has expected contents");
$fh->close();

# afsd.args  exists but no configuration defined: no change
set_file_contents($AFSD_ARGS_FILE,$AFSD_ARGS_EXPECTED);
$status = $comp->Configure_Afsd_Args($config_no_afsd_args);
ok(!$status, "Configure_Afsd_Args returned no explicit error");
$fh = get_file($AFSD_ARGS_FILE);
ok(defined($fh), $AFSD_ARGS_FILE." was opened");
is("$fh", $AFSD_ARGS_EXPECTED, $AFSD_ARGS_FILE." (no afsd_args in configuration) has expected contents");
$fh->close();

# afsd.args  exists but cleared in configuration
set_file_contents($AFSD_ARGS_FILE,$AFSD_ARGS_EXPECTED);
$status = $comp->Configure_Afsd_Args($config_empty_afsd_args);
ok(!$status, "Configure_Afsd_Args returned no explicit error");
$fh = get_file($AFSD_ARGS_FILE);
ok(defined($fh), $AFSD_ARGS_FILE." was opened");
is("$fh", "", $AFSD_ARGS_FILE." has been emptied");
$fh->close();

Test::NoWarnings::had_no_warnings();

