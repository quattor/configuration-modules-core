# -*- mode: cperl -*-
use strict;
use warnings;
use CAF::Object;
use FindBin qw($Bin);
use lib $Bin;
use Test::Quattor qw(profile1 profile_with_ldap);
use NCM::Component::postfix;
use Test::More; # skip_all => "No tests for now";
use CAF::Object;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::postfix->new('postfix');

my $cfg = get_config_for_profile("profile1");

my $rs = $cmp->Configure($cfg);

ok($rs, "Successfully run the component");

foreach my $f (qw(master.cf main.cf)) {
    ok(get_file("/etc/postfix/$f"),
       "File $f was written for the simple profile");
}

$cfg = get_config_for_profile("profile_with_ldap");
$rs = $cmp->Configure($cfg);


ok(get_command("/sbin/service postfix condrestart"),
   "Postfix daemon conditionally restarted by the component");

ok(get_file("/etc/postfix/ldap-aliases.cf"),
   "LDAP database file was written by the component, when present");

done_testing();
