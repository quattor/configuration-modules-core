use strict;
use warnings;
use Test::More tests => 10;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {
    ahost => {
        check_command => [qw(foo bar baz)],
        event_handler => [qw(hello world)],
        a             => 1,
        b             => 2,
        c             => [5 .. 7]
    }
};

my $rs = $comp->print_hosts($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{hosts}, "Correct file was opened");
like("$rs", qr(^\s*event_handler\s+hello!world$)m, "Event handler properly registered");
like("$rs", qr(^\s*check_command\s+foo!bar!baz$)m, "Check command properly registered");
like("$rs", qr(^\s*a\s+1$)m,                       "Random scalar key properly defined");
like("$rs", qr(^\s*c\s+5,6,7$)m,                   "Random array key properly defined");
like("$rs", qr(^\s*host_name\tahost$)m,            "Host name properly registered");
unlike("$rs", qr(address\t\d+\.\d+\.\d+\.\d+), "No IP address found for non-existing host");

$rs = $comp->print_hosts($t, ["ahost"]);
is("$rs", "", "Ignored hosts are not listed in configuration file");
$t = {"www.google.com" => $t->{ahost}};

$rs = $comp->print_hosts($t);
like("$rs", qr(address\s+\d+\.\d+\.\d+\.\d+), "IP address found for existing host");

$rs->close();
