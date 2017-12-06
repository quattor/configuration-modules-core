use strict;
use warnings;

use mock_rpc qw(nss);

use Test::Quattor;
use Test::More;
use CAF::Object;

$CAF::Object::NoAction = 1;


use File::Path qw(mkpath);

use NCM::Component::FreeIPA::NSS;
use NCM::Component::FreeIPA::Client;


my $db = 'target/test/nssdb';

my $n = NCM::Component::FreeIPA::NSS->new(
    $db,
    owner => 'user1',
    realm => 'REALM.DOMAIN',
    );

my $ipa = NCM::Component::FreeIPA::Client->new("host.example.com");


=head2 new

=cut

isa_ok($n, 'NCM::Component::FreeIPA::NSS', 'is a NCM::Component::FreeIPA::NSS instance');

is($n->{nssdb}, $db, "nssdb attribute set");
is_deeply($n->{perms}, {owner => 'user1'}, "owner set as part of perms attribute");
is($n->{realm}, 'REALM.DOMAIN', 'realm attribute set');
is($n->{canick}, 'REALM.DOMAIN IPA CA', 'IPA CA nick set based on realm');
is($n->{cacrt}, '/etc/ipa/ca.crt', "cacrt attribute set to IPA default");;
is($n->{csr_bits}, 4096, "default csr bits set");


=head2 setup

=cut

reset_caf_path();

# make temp workdir
ok($n->setup(), "setup returns success");
is($n->{workdir}, "/tmp/quattor_nss-XXXX", "workdir attribute set with tempdirectory");
diag explain $Test::Quattor::caf_path->{directory};
is_deeply($Test::Quattor::caf_path->{directory}, [
              [['/tmp/quattor_nss-XXXX'], {temp => 1, mode => 0700}],
              [['target/test/nssdb'], {owner => 'user1'}],
          ], "directory called with temp attr and 0700 mode");

# check

# calls setup_nssdb / init nssdb using certutil

=head2 add_cert_ca / add_cert_trusted / add_cert / has_cert / get_cert

=cut

ok($n->add_cert_trusted("mynick_t", "path/to/t_crt"), "add_cert_trusted ok");
ok(get_command("/usr/bin/certutil -d target/test/nssdb -A -n mynick_t -t CT,, -a -i path/to/t_crt"),
   "add_cert_trusted expected certutil command");

ok($n->add_cert_ca(), "add_cert_ca ok");
# It's ok with non-quoted spaces
ok(get_command('/usr/bin/certutil -d target/test/nssdb -A -n REALM.DOMAIN IPA CA -t CT,, -a -i /etc/ipa/ca.crt'),
   "add_cert_ca expected certutil command");

ok($n->add_cert("mynick", "path/to/crt"), "add_cert ok");
ok(get_command("/usr/bin/certutil -d target/test/nssdb -A -n mynick -t u,u,u -a -i path/to/crt"),
   "add_cert expected certutil command");

ok($n->has_cert("mynick"), "has_cert ok");
ok(get_command("/usr/bin/certutil -d target/test/nssdb -L -a -n mynick"),
   "has_cert expected certutil command");

reset_caf_path();
ok($n->get_cert("mynick", "path/to/cert_out"), "get_cert ok");
ok(get_command("/usr/bin/certutil -d target/test/nssdb -L -n mynick -a -o path/to/cert_out"),
   "get_cert expected certutil command");
is_deeply($Test::Quattor::caf_path->{directory}, [
              [["path/to"], {mode => 0755}],
          ], "directory called for cert basedir");

=head2 _mk_random_data / make_cert_request

=cut

$CAF::Object::NoAction = 0;

$n->{workdir} = "target/test/randomdata";
mkpath($n->{workdir});
my $fn = "$n->{workdir}/random_mynick.data";
my $nrbytes = 1234;
ok(! -f $fn, "random.data file does not exist before mk_random_data");
is($n->_mk_random_data($nrbytes, 'mynick'), $fn, "_mk_random_data return filename after succesful write");
ok(-f $fn, "random_mynick.data file exists after mk_random_data");
my ($fh, $data);
open($fh, '<', $fn);
# make sure we try to read more than what we expect
is(sysread($fh, $data, 2*$nrbytes), $nrbytes,
   "Was able to read $nrbytes bytes from random data file, tried to get twice as much");
close($fh);
unlink($fn);

ok(! -f $fn, "randomdata does not exist before make_cert_request");
is($n->make_cert_request("a.b.c.d", "mynick"), "$n->{workdir}/cert_a.b.c.d_mynick.csr", "make_cert_request returns csr filename");
ok(get_command('/usr/bin/certutil -d target/test/nssdb -R -g 4096 -s CN=a.b.c.d,O=REALM.DOMAIN -z target/test/randomdata/random_mynick.data -a -o target/test/randomdata/cert_a.b.c.d_mynick.csr'),
   "get_cert_request expected certutil command");
ok(-f $fn, "randomdata exists after make_cert_request (via mk_random_data)");

$CAF::Object::NoAction = 1;

=head2 ipa_request_cert

=cut

reset_POST_history;
set_file_contents('path/to/csr',
                  "-----BEGIN CERTIFICATE REQUEST-----\nCSRDATA\n-----END CERTIFICATE REQUEST-----");

ok($n->ipa_request_cert("path/to/csr", "path/to/crt", "g.h.i.j", $ipa), "ipa_request_cert ok");
ok(POST_history_ok(['cert_request -----BEGIN CERTIFICATE REQUEST-----\nCSRDATA\n-----END CERTIFICATE REQUEST----- principal=host/g.h.i.j@REALM.DOMAIN,vers',
                   "cert_show 1234 vers"]),
   "ipa_request_cert IPA POST ok");

=head2 get_priv_keys

=cut

reset_caf_path();
ok($n->get_privkey("mynickkey", "path/to/key", user => 'myuser1'), "get_priv_keys ok");
ok(get_command('/usr/bin/pk12util -o target/test/randomdata/p12keys/key.p12 -n mynickkey -d target/test/nssdb -W '),
   "pk12util command called");
ok(get_command('/usr/bin/openssl pkcs12 -in target/test/randomdata/p12keys/key.p12 -out path/to/key -nodes -password pass:'),
   "openssl command called");
is_deeply($Test::Quattor::caf_path->{directory}, [
              [["path/to"], {mode => 0755}],
              [["$n->{workdir}/p12keys"], {mode => 0700}],
          ], "directory called for key basedir and p12keys with 0700 mode");
is_deeply($Test::Quattor::caf_path->{status}, [
              [["path/to/key"], {user => 'myuser1'}],
          ], "status called on key with user");

# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
