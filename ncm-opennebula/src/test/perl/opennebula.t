# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(opennebula);
use NCM::Component::opennebula;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;


# DEBUG only (can't get the output in unittests otherwise)
sub dlog {
    my ($type, @args) = @_;
    diag("[".uc($type)."] ".join(" ", @args));
}
our $nco = new Test::MockModule('NCM::Component::opennebula');
foreach my $type ("error", "info", "verbose", "debug") {
	$nco->mock( $type, sub { shift; dlog($type, @_); } );
}

use OpennebulaMock;

$CAF::Object::NoAction = 1;



my $cmp = NCM::Component::opennebula->new("opennebula");

my $cfg = get_config_for_profile("opennebula");

$cmp->Configure($cfg);

ok(!exists($cmp->{ERROR}), "No errors found in normal execution");

done_testing();
