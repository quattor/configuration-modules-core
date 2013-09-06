# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(openldap);
use NCM::Component::openldap;


$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

my $cfg = get_config_for_profile('openldap');
my $cmp = NCM::Component::openldap->new('openldap');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $fh;
$fh = get_file("/etc/openldap/slapd.conf");
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter slapd.conf file written");

# generic
like($fh, qr/core.schema/m, "Include core.schema");

like($fh, qr/database\s*bdb/m, "Database type");


like($fh, qr/monitoring/m, "Monitoring");


done_testing();
