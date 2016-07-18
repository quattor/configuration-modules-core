# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;
use Test::Quattor qw(explicit);
use NCM::Component::afsclt;
use Readonly;
use CAF::Object;
Test::NoWarnings::clear_warnings();

=pod

=head1 SYNOPSIS

Tests for AFS CellServDB configuration

=cut

Readonly my $CELLSERVDB_FILE => '/usr/vice/etc/CellServDB';

Readonly my $CONFIG_PREFIX => '/software/components/afsclt';


sub get_config_tree {
    my $profile = shift;

    my $config = get_config_for_profile($profile);
    return $config->getElement($CONFIG_PREFIX)->getTree();
}


sub Check_CellServDB {
    my $msg = shift;

    my $fh = get_file($CELLSERVDB_FILE);
    ok(defined($fh), $CELLSERVDB_FILE." was opened ($msg)");
    
    if ( $fh ) {
        my @lines = split(/\n/, "$fh");
        # CellServDB valid contents may change, just check that it has a reasonable 
        # number of lines (more than 650 lines in July 2016) 
        my $contents_ok = @lines > 500;
        ok($contents_ok, "$CELLSERVDB_FILE content looks ok ($msg)");
        $fh->close();
    }
}


#############
# Main code #
#############


my $status;

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

my $comp = NCM::Component::afsclt->new('afsclt');

my $config = get_config_tree("explicit");

# Initial CellServDB doesn't exist
$status = $comp->Configure_CellServDB($config);
ok(!$status, "Configure_CellServDB returned no explicit error");
Check_CellServDB("No initial CellServDB");

Test::NoWarnings::had_no_warnings();

