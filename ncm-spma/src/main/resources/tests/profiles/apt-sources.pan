object template apt-sources;

include "components/spma/apt/schema";

'/software/components/spma' = dict(
    'packager', 'apt',
);
'/software/packages' = dict();

prefix '/software/repositories/0';
'name' = 'a_source';
'owner' = 'localuser@localdomain';
'enabled' = true;
'protocols' = list(
    dict(
        'name', 'http',
        'url', 'http://first.example.com/path/to/stuff trusty main',
    ),
    dict(
        'name', 'http',
        'url', 'http://another.example.org/another/path trusty main',
    ),
);
'includepkgs' = list(
    'foo',
    'bar',
);
'excludepkgs' = list(
    'baz',
    'quux',
);
