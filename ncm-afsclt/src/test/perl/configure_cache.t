# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;

use Test::More tests => 20;
use Test::NoWarnings;
use Test::Quattor qw(automatic automatic_nocachemount explicit);
use NCM::Component::afsclt;
use Readonly;
use CAF::Object;
Test::NoWarnings::clear_warnings();

=pod

=head1 SYNOPSIS

Tests for AFS client cache configuration

=cut

Readonly my $CACHEINFO_FILE => '/usr/vice/etc/cacheinfo';
Readonly my $CACHEINFO_AUTOMATIC => '/afs:/afscache:AUTOMATIC
';
Readonly my $CACHEINFO_AUTOMATIC_2 => '/afs::AUTOMATIC
';
Readonly my $CACHEINFO_EXPLICIT_SIZE => '/afs:/afscache:1422000
';
Readonly my $CACHEINFO_EXPLICIT_MOUNT => '/afsmnt:/var/afs/cache:1422000
';
Readonly my $FS_GETPARAMS_CMD => 'fs getcacheparms';
Readonly my $FS_GETPARAMS_OUTPUT_1 => "AFS using 1229334 of the cache's available 1422000 1K byte blocks.";

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

    my $status = $comp->Configure_Cache($config);
    ok(!$status, "Configure_Cache returned no explicit error");
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

my $config_automatic = get_config_tree("automatic");
my $config_no_cachemount = get_config_tree("automatic_nocachemount");
my $config_explicit = get_config_tree("explicit");

set_desired_output($FS_GETPARAMS_CMD, $FS_GETPARAMS_OUTPUT_1);

# cacheinfo doesn't exist
execute_standard_test($CACHEINFO_FILE, $CACHEINFO_AUTOMATIC, $config_automatic, "initially not existing");

# Initial cacheinfo file empty and cache mount point undefined
set_file_contents($CACHEINFO_FILE,"");
execute_standard_test($CACHEINFO_FILE, $CACHEINFO_AUTOMATIC_2, $config_no_cachemount, "cache mount undefined");

# Initial cacheinfo is the expected cacheinfo (size=AUTOMATIC)
set_file_contents($CACHEINFO_FILE,$CACHEINFO_AUTOMATIC);
execute_standard_test($CACHEINFO_FILE, $CACHEINFO_AUTOMATIC, $config_automatic, "initial contents ok");

# Initial cacheinfo file with explicit size, expected AUTOMATIC
set_file_contents($CACHEINFO_FILE,$CACHEINFO_EXPLICIT_SIZE);
execute_standard_test($CACHEINFO_FILE, $CACHEINFO_AUTOMATIC, $config_automatic, "initially explicit size");

# Initial cacheinfo file  with size=AUTOMATIC, expected explicit size
set_file_contents($CACHEINFO_FILE,$CACHEINFO_AUTOMATIC);
execute_standard_test($CACHEINFO_FILE, $CACHEINFO_EXPLICIT_MOUNT, $config_explicit, "initially AUTOMATIC");


# Initial cacheinfo size ok but cache mount point changed
set_file_contents($CACHEINFO_FILE,$CACHEINFO_EXPLICIT_SIZE);
execute_standard_test($CACHEINFO_FILE, $CACHEINFO_EXPLICIT_MOUNT, $config_explicit, "cache mount point changed");

Test::NoWarnings::had_no_warnings();

