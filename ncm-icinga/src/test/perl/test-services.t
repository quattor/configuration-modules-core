#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

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
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{services});
like($fh, qr(^\s*service_description\taservice$)m, "Service description properly registered");
like($fh, qr(^\s*check_command\s+1!2$)m,           "Check command properly registered");
like($fh, qr(^\s*event_handler\s+3!4$)m,           "Event handler properly registered");
like($fh, qr(^\s*event_handler_enabled\s+1$)m,     "Event handler is enabled");
like($fh, qr(^\s*foo\s+5,6$)m,                     "Random array field is properly displayed");
