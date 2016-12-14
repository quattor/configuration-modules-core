#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Quattor qw(aii-basic);
use NCM::Component::freeipa;
use NCM::Component::ks;
use CAF::Object;
use Test::MockModule;

$CAF::Object::NoAction = 1;

use mock_rpc qw(aii-basic);

my $mockk = Test::MockModule->new('CAF::Kerberos');
my $krb5;
$mockk->mock('get_context', sub {$krb5 = shift; return 1;});

my $cfg = get_config_for_profile('aii-basic');

my $aii = NCM::Component::freeipa->new("freeipa");
isa_ok ($aii, "NCM::Component::freeipa",
        "NCM::Component::freeipa correctly instantiated");

my $path;

=head1 Test remove hook/method

=cut

$path = "/system/aii/hooks/remove/0";
reset_POST_history;
ok($aii->aii_remove($cfg, $path), 'aii remove ok');
ok(POST_history_ok([
       "host_disable myhost.example.com version",
   ]), "host_disable called");

# Correct Host remove/disable command

=head2 Test ks post_reboot hook/method

=cut


mkdir 'target/test' if ! -d 'target/test';

my $fh = CAF::FileWriter->new("target/test/ks");
select($fh);

reset_POST_history;
ok($aii->aii_post_reboot($cfg, $path), 'aii post_reboot ok');

# Correct host add / host-mod command
ok(POST_history_ok([
       "host_add myhost.example.com ip_address=1.2.3.4,macaddress=aa:bb:cc:dd:ee:ff,version",
       "host_mod myhost.example.com random=1,version",
   ]), "host_add / host_mod called");


like($fh, qr(^yum -y install ncm-freeipa nss-pam-ldapd ipa-client nss-tools openssl -c /tmp/aii/yum/yum.conf$)m,
     "install freeipa component and CLI dependencies in post_reboot");
like($fh, qr(^PERL5LIB=/usr/lib/perl perl -MNCM::Component::FreeIPA::CLI -w -e install -- --realm MY.REALM --primary myhost.example.com --domain com --fqdn myhost.example.com --hostcert 1 --otp supersecretOTP$)m,
     "CLI called as expected");

# close the selected FH and reset STDOUT
NCM::Component::ks::ksclose;

# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
