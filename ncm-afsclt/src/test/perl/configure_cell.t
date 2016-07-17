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

    my $status = $comp->Configure_Cell($config);
    ok(!$status, "Configure_Cell returned no explicit error");
    my $fh = get_file($file);
    ok(defined($fh), $file." was opened ($msg)");
    is("$fh", $expected_contents, $file." has expected contents ($msg)");
    $fh->close();
}


#############
# Main code #
#############


my $fh;
my $status;

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

$comp = NCM::Component::afsclt->new('afsclt');

my $config_explicit = get_config_tree("explicit");

# Initial ThisCell file empty
set_file_contents($THISCELL_FILE,"");
execute_standard_test($THISCELL_FILE, $THISCELL_EXPECTED, $config_explicit, "initially empty");

# Initial ThisCell content different from expected one
set_file_contents($THISCELL_FILE,"abcdefg");
execute_standard_test($THISCELL_FILE, $THISCELL_EXPECTED, $config_explicit, "initial contents wrong");

# Initial ThisCell content matching expected one
set_file_contents($THISCELL_FILE,$THISCELL_EXPECTED);
execute_standard_test($THISCELL_FILE, $THISCELL_EXPECTED, $config_explicit, "initial contents ok");

Test::NoWarnings::had_no_warnings();

