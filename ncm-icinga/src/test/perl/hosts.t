use strict;
use warnings;
use Test::More tests => 8;

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
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{hosts});

like($fh, qr(^\s*event_handler\s+hello!world$)m, "Event handler properly registered");
like($fh, qr(^\s*check_command\s+foo!bar!baz$)m, "Check command properly registered");
like($fh, qr(^\s*a\s+1$)m,                       "Random scalar key properly defined");
like($fh, qr(^\s*c\s+5,6,7$)m,                   "Random array key properly defined");
like($fh, qr(^\s*host_name\tahost$)m,            "Host name properly registered");
unlike($fh, qr(address\t\d+\.\d+\.\d+\.\d+), "No IP address found for non-existing host");

$rs = $comp->print_hosts($t, ["ahost"]);
$fh = get_file(NCM::Component::icinga::ICINGA_FILES->{hosts});
is("$fh", "", "Ignored hosts are not listed in configuration file");

$t = {"www.google.com" => $t->{ahost}};

$rs = $comp->print_hosts($t);
$fh = get_file(NCM::Component::icinga::ICINGA_FILES->{hosts});
like("$fh", qr(address\s+\d+\.\d+\.\d+\.\d+), "IP address found for existing host");
