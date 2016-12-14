object template basic_crushmap;

variable BASE_STEPS = list(
    dict(
        'take', 'default',
        'set_chooseleaf_tries', 5,
        'choices', list(
        dict(
            'chtype', 'chooseleaf firstn',
            'number', 0,
            'bktype', 'host',
            ),
        ),
    ),
);

prefix '/';
'types' = list(
    dict('type_id', 0, 'name', 'osd'),
    dict('type_id', 1, 'name', 'host')
);

'devices' = list(
    dict('id', 0, 'name', 'osd.0'),
    dict('id', 1, 'name', 'osd.1')
);

'rules/0/name' = 'data';
'rules/0/steps' = BASE_STEPS;
'rules/0/ruleset' = 1;
'rules/0/type' = 'ec';
'rules/0/min_size' = 1;
'rules/0/max_size' = 5;


'buckets/0/name' = 'default';
'buckets/0/type' = 'root';
'buckets/0/hash' = 0;
'buckets/0/alg' = 'straw2';
'buckets/0/id' = 0;
'buckets/0/weight' = 174.5;
'buckets/0/items' = list(
    dict('name', 'ceph001', 'weight', 70),
    dict('name', 'ceph002', 'weight', 70)
);

'buckets/1/name' = 'ceph001';
'buckets/1/type' = 'host';
'buckets/1/hash' = 0;
'buckets/1/alg' = 'straw2';
'buckets/1/id' = 0;
'buckets/1/weight' = 174.5;

'buckets/2/name' = 'osd.0';
'buckets/2/type' = 'osd';
'buckets/2/weight' = 74.5;

'tunables/test_tune' = 0;
