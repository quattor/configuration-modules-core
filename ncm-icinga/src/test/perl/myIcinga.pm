use strict;
use warnings;

use Test::Quattor;

use CAF::Object;
$CAF::Object::NoAction = 1;

use subs qw(NCM::Component::icinga::ICINGAUSR NCM::Component::icinga::ICINGAGRP);
use NCM::Component::icinga;

sub NCM::Component::icinga::ICINGAUSR {
    return $<;
};

sub NCM::Component::icinga::ICINGAGRP {
    my @grps=split(" ", $();
    return $grps[0];
};
