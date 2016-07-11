use strict;
use warnings;

use Test::More;
use Test::Quattor qw(client);
use Test::MockModule;
use CAF::Object;

$CAF::Object::NoAction = 1;

use NCM::Component::FreeIPA::Bootstrap;

my @args = qw(--realm MY.REALM --primary primary.example.com --otp abcdef123456 --domain example.com --short thishost --debug 5);
my $bs = NCM::Component::FreeIPA::Bootstrap->new('this script', @args);

foreach my $class (qw(NCM::Component::FreeIPA::Bootstrap CAF::Application NCM::Component::freeipa CAF::Reporter)) {
    isa_ok($bs, $class, "is a $class instance");
}

done_testing();
