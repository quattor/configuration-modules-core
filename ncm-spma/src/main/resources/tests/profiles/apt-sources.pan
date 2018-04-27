object template apt-sources;

include "components/spma/apt/schema";

'/software/components/spma' = dict(
    'packager', 'apt',
);
'/software/packages' = dict();

prefix '/software/repositories/0';
'name' = 'standard_source';
'owner' = 'localuser@localdomain';
'enabled' = true;
'gpgcheck' = true;
'protocols' = list(
    dict(
        'name', 'http',
        'url', 'http://first.example.com/path/to/stuff trusty main',
    ),
    dict(
        'name', 'http',
        'url', 'https://second.example.com/path/to/things trusty main',
    ),
);
'includepkgs' = list(
    'foo',
);
'excludepkgs' = list(
    'baz',
);

prefix '/software/repositories/1';
'name' = 'trusted_source';
'owner' = 'localuser@localdomain';
'enabled' = true;
'gpgcheck' = false;
'protocols' = list(
    dict(
        'name', 'http',
        'url', 'http://another.example.org/another/path trusty main',
    ),
);
'includepkgs' = list(
    'bar',
);
'excludepkgs' = list(
    'quux',
);
