# -*- mode: cperl -*-
use strict;
use warnings;
use CAF::Object;
use FindBin qw($Bin);
use lib $Bin;
use Test::Quattor qw(%files_contents %commands_run);
use NCM::Component::postfix;
use Test::More;
use CAF::Object;
no strict 'refs';

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::postfix->new('postfix');

my $ldap = { my_arbitrary_db => {
				 bind_dn => 'OU=foo,CN=bar',
				 bind => 1,
				 starttls => 0
				},
	     my_also_arbitrary_db => {
				      debuglevel => 5
				     }
	   };

my $rs = $cmp->handle_databases({ldap => $ldap });

ok($rs, "Successfully handled the LDAP config file");

while (my ($db, $cfg) = each($ldap)) {
    ok(exists($Test::Quattor::files_contents{"/etc/postfix/$db"}),
       "Database $db correctly created");
    my $fh = $Test::Quattor::files_contents{"/etc/postfix/$db"};
    while (my ($k, $v) = each(%$cfg)) {
	like($fh, qr{^$k\s*=}m,
	     "Database $db contains key $k");
    }
}

done_testing();
