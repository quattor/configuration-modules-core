# -*- mode: cperl -*-
use strict;
use warnings;
use CAF::Object;
use Test::Quattor;
use NCM::Component::postfix;
use Test::More;

use Test::Quattor::TextRender::Base;
$CAF::Object::NoAction = 1;
my $caf_trd = mock_textrender();

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

while (my ($db, $cfg) = each(%$ldap)) {
    my $fh = get_file("/etc/postfix/$db");
    ok(defined($fh), "Database $db correctly created");
    while (my ($k, $v) = each(%$cfg)) {
	like($fh, qr{^$k\s*=}m,
	     "Database $db contains key $k");
    }
}

done_testing();
