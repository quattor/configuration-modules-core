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

    my $status = $comp->Configure_Afsd_Args($config);
    ok(!$status, "Configure_Afsd_Args returned no explicit error");
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

my $config_afsd_args = get_config_tree("explicit");
my $config_empty_afsd_args = get_config_tree("automatic_nocachemount");
my $config_no_afsd_args = get_config_tree("automatic");

# Initial afsd.args doesn't exist
execute_standard_test($AFSD_ARGS_FILE, $AFSD_ARGS_EXPECTED, $config_afsd_args, "initially not existing");

# Initial afsd.args content different from expected one
set_file_contents($AFSD_ARGS_FILE,"abcdefg");
execute_standard_test($AFSD_ARGS_FILE, $AFSD_ARGS_EXPECTED, $config_afsd_args, "initial content wrong");

# Initial afsd.args content matching expected one
set_file_contents($AFSD_ARGS_FILE,$AFSD_ARGS_EXPECTED);
execute_standard_test($AFSD_ARGS_FILE, $AFSD_ARGS_EXPECTED, $config_afsd_args, "initial content ok");

# afsd.args  exists but no configuration defined: no change
set_file_contents($AFSD_ARGS_FILE,$AFSD_ARGS_EXPECTED);
execute_standard_test($AFSD_ARGS_FILE, $AFSD_ARGS_EXPECTED, $config_no_afsd_args, "no afsd_args in configuration");

# afsd.args  exists but cleared in configuration
set_file_contents($AFSD_ARGS_FILE,$AFSD_ARGS_EXPECTED);
execute_standard_test($AFSD_ARGS_FILE, $AFSD_ARGS_EXPECTED, $config_no_afsd_args, "afsd.args cleared");

Test::NoWarnings::had_no_warnings();

