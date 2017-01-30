use strict;
use warnings;

use Test::More;
use Test::Quattor;
use Test::MockModule;
use CAF::Object;

$CAF::Object::NoAction = 1;

use NCM::Component::FreeIPA::CLI;

mkdir 'target/test';
mkdir 'target/test/cli';

my @args = qw(--realm MY.REALM --primary primary.example.com --otp abcdef123456 --domain example.com --fqdn thishost.sub.domain.com --debug 5 --logfile target/test/cli/cli.log --hostcert 1);
my $cli = NCM::Component::FreeIPA::CLI->new('this script', @args);

foreach my $class (qw(NCM::Component::FreeIPA::CLI CAF::Application NCM::Component::freeipa CAF::Reporter)) {
    isa_ok($cli, $class, "is a $class instance");
}

# Test exported functions
no strict 'refs';
foreach my $func (qw(install)) {
    is(ref(\&{$func}), 'CODE', "func $func is an exported function");
}
use strict 'refs';


done_testing();
