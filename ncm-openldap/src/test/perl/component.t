# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(openldap);
use NCM::Component::openldap;
use Test::MockModule;
use Test::Quattor::RegexpTest;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

my $mock = Test::MockModule->new('NCM::Component::openldap');
$mock->mock('_directory_exists', 1);
$mock->mock('valid_config', 1);

my $cfg = get_config_for_profile('openldap');
my $cmp = NCM::Component::openldap->new('openldap');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $fh;
$fh = get_file("/etc/openldap/slapd.conf");
isa_ok($fh, "CAF::FileWriter",
       "This is a CAF::FileWriter slapd.conf file written");

# generic
like($fh, qr/core.schema/m, "Include core.schema");
like($fh, qr/database\s*bdb/m, "Database type");
like($fh, qr/monitoring/m, "Monitoring");

# full test
my $rt = Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/slapd_conf_regexptest',
    text => "$fh",
    );
$rt->test();


$fh = get_file("/var/lib/ldap/DB_CONFIG");
isa_ok($fh, "CAF::FileWriter", 
       "This is a CAF::FileWriter DB_CONFIG file written");
$rt = Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/db_config_regexptest',
    text => "$fh",
    );
$rt->test();


done_testing();
