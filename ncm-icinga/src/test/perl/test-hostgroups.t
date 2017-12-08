use strict;
use warnings;
use Test::More tests => 4;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = {
    agroup => {
        alias   => 'a',
        members => [1 .. 3]
    }
};

my $rs = $comp->print_hostgroups($t);
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{hostgroups});

like($fh, qr(^\s*hostgroup_name\tagroup$)m, "Hostgroup name properly registered");
like($fh, qr(^\s*alias\s+a$)m,              "Alias properly registered");
like($fh, qr(^\s*members\s+1,2,3$)m,        "All members registered");

$rs = $comp->print_hostgroups($t, [1]);
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{hostgroups});

like($fh, qr(^\s*members\s+2,3$)m, "Unwanted member ignored");
