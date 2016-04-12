use strict;
use warnings;
use Test::More tests => 6;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {
    agroup => {
        alias   => 'a',
        members => [1 .. 3]
    }
};

my $rs = $comp->print_hostgroups($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{hostgroups}, "Correct file was opened");
like("$rs", qr(^\s*hostgroup_name\tagroup$)m, "Hostgroup name properly registered");
like("$rs", qr(^\s*alias\s+a$)m,              "Alias properly registered");
like("$rs", qr(^\s*members\s+1,2,3$)m,        "All members registered");

$rs = $comp->print_hostgroups($t, [1]);
like("$rs", qr(^\s*members\s+2,3$)m, "Unwanted member ignored");

$rs->close();
