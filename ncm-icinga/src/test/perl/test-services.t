#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;

use myIcinga;
my $comp = NCM::Component::icinga->new('icinga');

my $t = {
    aservice => [
        {
            check_command         => [1, 2],
            event_handler         => [3, 4],
            foo                   => [5, 6],
            event_handler_enabled => 1,
        }
    ]
};

my $rs = $comp->print_services($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{services}, "Correct file was opened");
like("$rs", qr(^\s*service_description\taservice$)m, "Service description properly registered");
like("$rs", qr(^\s*check_command\s+1!2$)m,           "Check command properly registered");
like("$rs", qr(^\s*event_handler\s+3!4$)m,           "Event handler properly registered");
like("$rs", qr(^\s*event_handler_enabled\s+1$)m,     "Event handler is enabled");
like("$rs", qr(^\s*foo\s+5,6$)m,                     "Random array field is properly displayed");

$rs->close();
