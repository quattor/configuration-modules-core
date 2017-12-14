use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::getpwnam = sub {
        return getpwuid $< ;
    };
}

use Test::Quattor;
use NCM::Component::icinga;

1;
