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

Tests for AFS client cache configuration

=cut

Readonly my $CACHEINFO_FILE => '/usr/vice/etc/cacheinfo';
Readonly my $CACHEINFO_AUTOMACTIC => '/afs:/afscache:AUTOMATIC
';
Readonly my $CACHEINFO_AUTOMACTIC_2 => '/afs::AUTOMATIC
';
Readonly my $CACHEINFO_EXPLICIT_SIZE => '/afs:/afscache:1422000
';
Readonly my $CACHEINFO_EXPLICIT_MOUNT => '/afsmnt:/var/afs/cache:1422000
';
Readonly my $FS_GETPARAMS_CMD => 'fs getcacheparms';
Readonly my $FS_GETPARAMS_OUTPUT_1 => "AFS using 1229334 of the cache's available 1422000 1K byte blocks.";

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

my $config_automatic = get_config_tree("automatic");
my $config_no_cachemount = get_config_tree("automatic_nocachemount");
my $config_explicit = get_config_tree("explicit");

set_desired_output($FS_GETPARAMS_CMD, $FS_GETPARAMS_OUTPUT_1);

# cacheinfo doesn't exist
$status = $comp->Configure_Cache($config_automatic);
ok(!$status, "Configure_Cache returned no explicit error");
$fh = get_file($CACHEINFO_FILE);
ok(defined($fh), $CACHEINFO_FILE." was opened");
is("$fh", $CACHEINFO_AUTOMACTIC, $CACHEINFO_FILE." (initially not existing) has expected contents");
$fh->close();

# Initial cacheinfo file empty and cache mount point undefined
set_file_contents($CACHEINFO_FILE,"");
$status = $comp->Configure_Cache($config_no_cachemount);
ok(!$status, "Configure_Cache returned no explicit error");
$fh = get_file($CACHEINFO_FILE);
ok(defined($fh), $CACHEINFO_FILE." was opened");
is("$fh", $CACHEINFO_AUTOMACTIC_2, $CACHEINFO_FILE." (cache mount undefined) has expected contents");
$fh->close();

# Initial cacheinfo is the expected cacheinfo (size=AUTOMATIC)
set_file_contents($CACHEINFO_FILE,$CACHEINFO_AUTOMACTIC);
$status = $comp->Configure_Cache($config_automatic);
ok(!$status, "Configure_Cache returned no explicit error");
$fh = get_file($CACHEINFO_FILE);
ok(defined($fh), $CACHEINFO_FILE." was opened");
is("$fh", $CACHEINFO_AUTOMACTIC, $CACHEINFO_FILE." (initially expected) has expected contents");
$fh->close();

# Initial cacheinfo file with explicit size, expected AUTOMATIC
set_file_contents($CACHEINFO_FILE,$CACHEINFO_EXPLICIT_SIZE);
$status = $comp->Configure_Cache($config_automatic);
ok(!$status, "Configure_Cache returned no explicit error");
$fh = get_file($CACHEINFO_FILE);
ok(defined($fh), $CACHEINFO_FILE." was opened");
is("$fh", $CACHEINFO_AUTOMACTIC, $CACHEINFO_FILE." (initially explicit size) has expected contents");
$fh->close();

# Initial cacheinfo file  with size=AUTOMATIC, expected explicit size
set_file_contents($CACHEINFO_FILE,$CACHEINFO_AUTOMACTIC);
$status = $comp->Configure_Cache($config_explicit);
ok(!$status, "Configure_Cache returned no explicit error");
$fh = get_file($CACHEINFO_FILE);
ok(defined($fh), $CACHEINFO_FILE." was opened");
is("$fh", $CACHEINFO_EXPLICIT_MOUNT, $CACHEINFO_FILE." (initially AUTOMATIC) has expected contents");
$fh->close();



Test::NoWarnings::had_no_warnings();

