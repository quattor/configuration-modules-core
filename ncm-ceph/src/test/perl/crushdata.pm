# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod
=head1 ceph data examples
# Test the runs of ceph commands

=cut

package crushdata;

use strict;
use warnings;

use Readonly;
Readonly our $CRUSHMAP_01 => '{"devices":[{"id":0,"name":"osd.0"},{"id":1,"name":"osd.1"},{"id":2,"name":"osd.2"},{"id":3,"name":"osd.3"},{"id":4,"name":"osd.4"},{"id":5,"name":"osd.5"},{"id":6,"name":"osd.6"},{"id":7,"name":"osd.7"},{"id":8,"name":"osd.8"},{"id":9,"name":"osd.9"},{"id":10,"name":"osd.10"},{"id":11,"name":"osd.11"},{"id":12,"name":"osd.12"},{"id":13,"name":"osd.13"},{"id":14,"name":"osd.14"},{"id":15,"name":"osd.15"},{"id":16,"name":"osd.16"},{"id":17,"name":"osd.17"},{"id":18,"name":"osd.18"},{"id":19,"name":"osd.19"},{"id":20,"name":"osd.20"},{"id":21,"name":"osd.21"},{"id":22,"name":"osd.22"},{"id":23,"name":"osd.23"},{"id":24,"name":"osd.24"},{"id":25,"name":"osd.25"},{"id":26,"name":"osd.26"},{"id":27,"name":"osd.27"},{"id":28,"name":"osd.28"},{"id":29,"name":"osd.29"},{"id":30,"name":"osd.30"},{"id":30,"name":"osd.30"},{"id":31,"name":"osd.31"},{"id":32,"name":"osd.32"},{"id":33,"name":"osd.33"},{"id":34,"name":"osd.34"},{"id":35,"name":"osd.35"}],"types":[{"type_id":0,"name":"osd"},{"type_id":1,"name":"host"},{"type_id":2,"name":"rack"},{"type_id":3,"name":"row"},{"type_id":4,"name":"room"},{"type_id":5,"name":"datacenter"},{"type_id":6,"name":"root"}],"buckets":[{"id":-1,"name":"default","type_id":6,"type_name":"root","weight":5725225,"alg":"straw","hash":"rjenkins1","items":[{"id":-5,"weight":5725225,"pos":0},{"id":-6,"weight":0,"pos":1}]},{"id":-2,"name":"ceph001","type_id":1,"type_name":"host","weight":2862612,"alg":"straw","hash":"rjenkins1","items":[{"id":0,"weight":238551,"pos":0},{"id":1,"weight":238551,"pos":1},{"id":2,"weight":238551,"pos":2},{"id":3,"weight":238551,"pos":3},{"id":4,"weight":238551,"pos":4},{"id":5,"weight":238551,"pos":5},{"id":6,"weight":238551,"pos":6},{"id":7,"weight":238551,"pos":7},{"id":8,"weight":238551,"pos":8},{"id":9,"weight":238551,"pos":9},{"id":10,"weight":238551,"pos":10},{"id":11,"weight":238551,"pos":11}]},{"id":-3,"name":"ceph002","type_id":1,"type_name":"host","weight":2862612,"alg":"straw","hash":"rjenkins1","items":[{"id":12,"weight":238551,"pos":0},{"id":13,"weight":238551,"pos":1},{"id":14,"weight":238551,"pos":2},{"id":15,"weight":238551,"pos":3},{"id":16,"weight":238551,"pos":4},{"id":17,"weight":238551,"pos":5},{"id":18,"weight":238551,"pos":6},{"id":19,"weight":238551,"pos":7},{"id":20,"weight":238551,"pos":8},{"id":21,"weight":238551,"pos":9},{"id":22,"weight":238551,"pos":10},{"id":23,"weight":238551,"pos":11}]},{"id":-4,"name":"ceph003","type_id":1,"type_name":"host","weight":0,"alg":"straw","hash":"rjenkins1","items":[]},{"id":-5,"name":"test1","type_id":2,"type_name":"rack","weight":5725224,"alg":"straw","hash":"rjenkins1","items":[{"id":-2,"weight":2862612,"pos":0},{"id":-3,"weight":2862612,"pos":1}]},{"id":-6,"name":"test2","type_id":2,"type_name":"rack","weight":0,"alg":"straw","hash":"rjenkins1","items":[{"id":-4,"weight":0,"pos":0}]}],"rules":[{"rule_id":0,"rule_name":"data","ruleset":0,"type":1,"min_size":1,"max_size":10,"steps":[{"op":"take","item":-1},{"op":"chooseleaf_firstn","num":0,"type":"host"},{"op":"emit"}]},{"rule_id":1,"rule_name":"metadata","ruleset":1,"type":1,"min_size":1,"max_size":10,"steps":[{"op":"take","item":-1},{"op":"chooseleaf_firstn","num":0,"type":"host"},{"op":"emit"}]},{"rule_id":2,"rule_name":"rbd","ruleset":2,"type":1,"min_size":1,"max_size":10,"steps":[{"op":"take","item":-1},{"op":"chooseleaf_firstn","num":0,"type":"host"},{"op":"emit"}]}],"tunables":{"choose_local_tries":2,"choose_local_fallback_tries":5,"choose_total_tries":19,"chooseleaf_descend_once":0}}';

Readonly::Array our @REBUCKETS => (
   {
     'buckets' => [
       {
         'name' => 'ceph001',
         'type' => 'host'
       },
       {
         'name' => 'ceph002',
         'type' => 'host'
       },
       {
         'name' => 'ceph003',
         'type' => 'host'
       }
     ],
     'defaultalg' => 'straw',
     'defaulthash' => '0',
     'name' => 'default',
     'type' => 'root'
   }
);

Readonly::Array our @RELBBUCKETS => (
     {
       'buckets' => [
         {
           'buckets' => [
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             }
           ],
           'name' => 'ceph001',
           'type' => 'host'
         },
         {
           'buckets' => [
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             }
           ],
           'name' => 'ceph002',
           'type' => 'host'
         },
         {
           'buckets' => [
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-0'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             },
             {
               'labels' => [
                 'tst-1'
               ],
               'name' => 'osd.0',
               'type' => 'osd',
               'weight' => '1'
             }
           ],
           'name' => 'ceph003',
           'type' => 'host'
         }
       ],
       'defaultalg' => 'straw',
       'defaulthash' => '0',
       'labels' => [
         'tst-0',
         'tst-1'
       ],
       'name' => 'default',
       'type' => 'root'
     }
);

Readonly::Array our @LBBUCKETS => (
   {
     'buckets' => [
       {
         'buckets' => [
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           }
         ],
         'name' => 'ceph001-tst-0',
         'type' => 'host'
       },
       {
         'buckets' => [
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           }
         ],
         'name' => 'ceph002-tst-0',
         'type' => 'host'
       },
       {
         'buckets' => [
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           }
         ],
         'name' => 'ceph003-tst-0',
         'type' => 'host'
       }
     ],
     'defaultalg' => 'straw',
     'defaulthash' => '0',
     'name' => 'default-tst-0',
     'type' => 'root'
   },
   {
     'buckets' => [
       {
         'buckets' => [
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           }
         ],
         'name' => 'ceph001-tst-1',
         'type' => 'host'
       },
       {
         'buckets' => [
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           }
         ],
         'name' => 'ceph002-tst-1',
         'type' => 'host'
       },
       {
         'buckets' => [
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           },
           {
             'name' => 'osd.0',
             'type' => 'osd',
             'weight' => '1'
           }
         ],
         'name' => 'ceph003-tst-1',
         'type' => 'host'
       }
     ],
     'defaultalg' => 'straw',
     'defaulthash' => '0',
     'name' => 'default-tst-1',
     'type' => 'root'
   }
);

Readonly::Array our @FLBUCKETS => (
   {
     'alg' => 'straw',
     'hash' => '0',
     'name' => 'ceph001',
     'type' => 'host'
   },
   {
     'alg' => 'straw',
     'hash' => '0',
     'name' => 'ceph002',
     'type' => 'host'
   },
   {
     'alg' => 'straw',
     'hash' => '0',
     'name' => 'ceph003',
     'type' => 'host'
   },
   {
     'alg' => 'straw',
     'defaultalg' => 'straw',
     'defaulthash' => '0',
     'hash' => '0',
     'items' => [
       {
         'name' => 'ceph001',
         'weight' => undef
       },
       {
         'name' => 'ceph002',
         'weight' => undef
       },
       {
         'name' => 'ceph003',
         'weight' => undef
       }
     ],
     'name' => 'default',
     'type' => 'root'
   }
);
Readonly::Hash our %QUATMAP => (
   'buckets' => [
     {
       'alg' => 'straw',
       'items' => [
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         }
       ],
       'hash' => '0',
       'name' => 'ceph001',
       'type' => 'host',
       'weight' => 12
     },
     {
       'alg' => 'straw',
       'items' => [
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         }
       ],
       'hash' => '0',
       'name' => 'ceph002',
       'type' => 'host',
       'weight' => 12
     },
     {
       'alg' => 'straw',
       'items' => [
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         }
       ],
       'hash' => '0',
       'name' => 'ceph003',
       'type' => 'host',
       'weight' => 12
     },
     {
       'alg' => 'straw',
       'items' => [
         {
           'name' => 'ceph001',
           'weight' => 12
         },
         {
           'name' => 'ceph002',
           'weight' => 12
         },
         {
           'name' => 'ceph003',
           'weight' => 12
         }
       ],
       'hash' => '0',
       'defaultalg' => 'straw',
       'defaulthash' => '0',
       'name' => 'default',
       'type' => 'root',
       'weight' => 36
     }
   ],
   'devices' => [
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 0,
       'name' => 'osd.0'
     }
   ],
   'rules' => [
     {
       'name' => 'data',
       'type' => 'replicated',
       'min_size' => 0,
       'max_size' => 10,
       'steps' => [
         {
           'choices' => [
             {
               'bktype' => 'host',
               'chtype' => 'chooseleaf firstn',
               'number'  => 0,
             }
           ],
           'take' => 'default'
         }
       ]
     },
     {
       'name' => 'metadata',
       'type' => 'replicated',
       'min_size' => 0,
       'max_size' => 10,
       'steps' => [
         {
           'choices' => [
             {
               'bktype' => 'host',
               'chtype' => 'chooseleaf firstn',
               'number'  => 0,

             }
           ],
           'take' => 'default'
         }
       ]
     },
     {
       'name' => 'rbd',
       'type' => 'replicated',
       'min_size' => 0,
       'max_size' => 10,
       'steps' => [
         {
           'choices' => [
             {
               'bktype' => 'host',
               'chtype' => 'chooseleaf firstn',
               'number'  => 0,
             }
           ],
           'take' => 'default'
         }
       ]
     }
   ],
   'types' => [
     {
       'name' => 'osd',
       'type_id' => 0
     },
     {
       'name' => 'host',
       'type_id' => 1
     },
     {
       'name' => 'root',
       'type_id' => 2
     }
   ]
);
Readonly::Hash our %CEPHMAP => (
   'buckets' => [
     {
       'alg' => 'straw',
       'hash' => 'rjenkins1',
       'id' => -1,
       'items' => [
         {
           'id' => -5,
           'pos' => 0,
           'weight' => 5725225
         },
         {
           'id' => -6,
           'pos' => 1,
           'weight' => 0
         }
       ],
       'name' => 'default',
       'type_id' => 6,
       'type_name' => 'root',
       'weight' => 5725225
     },
     {
       'alg' => 'straw',
       'hash' => 'rjenkins1',
       'id' => -2,
       'items' => [
         {
           'id' => 0,
           'pos' => 0,
           'weight' => 238551
         },
         {
           'id' => 1,
           'pos' => 1,
           'weight' => 238551
         },
         {
           'id' => 2,
           'pos' => 2,
           'weight' => 238551
         },
         {
           'id' => 3,
           'pos' => 3,
           'weight' => 238551
         },
         {
           'id' => 4,
           'pos' => 4,
           'weight' => 238551
         },
         {
           'id' => 5,
           'pos' => 5,
           'weight' => 238551
         },
         {
           'id' => 6,
           'pos' => 6,
           'weight' => 238551
         },
         {
           'id' => 7,
           'pos' => 7,
           'weight' => 238551
         },
         {
           'id' => 8,
           'pos' => 8,
           'weight' => 238551
         },
         {
           'id' => 9,
           'pos' => 9,
           'weight' => 238551
         },
         {
           'id' => 10,
           'pos' => 10,
           'weight' => 238551
         },
         {
           'id' => 11,
           'pos' => 11,
           'weight' => 238551
         }
       ],
       'name' => 'ceph001',
       'type_id' => 1,
       'type_name' => 'host',
       'weight' => 2862612
     },
     {
       'alg' => 'straw',
       'hash' => 'rjenkins1',
       'id' => -3,
       'items' => [
         {
           'id' => 12,
           'pos' => 0,
           'weight' => 238551
         },
         {
           'id' => 13,
           'pos' => 1,
           'weight' => 238551
         },
         {
           'id' => 14,
           'pos' => 2,
           'weight' => 238551
         },
         {
           'id' => 15,
           'pos' => 3,
           'weight' => 238551
         },
         {
           'id' => 16,
           'pos' => 4,
           'weight' => 238551
         },
         {
           'id' => 17,
           'pos' => 5,
           'weight' => 238551
         },
         {
           'id' => 18,
           'pos' => 6,
           'weight' => 238551
         },
         {
           'id' => 19,
           'pos' => 7,
           'weight' => 238551
         },
         {
           'id' => 20,
           'pos' => 8,
           'weight' => 238551
         },
         {
           'id' => 21,
           'pos' => 9,
           'weight' => 238551
         },
         {
           'id' => 22,
           'pos' => 10,
           'weight' => 238551
         },
         {
           'id' => 23,
           'pos' => 11,
           'weight' => 238551
         }
       ],
       'name' => 'ceph002',
       'type_id' => 1,
       'type_name' => 'host',
       'weight' => 2862612
     },
     {
       'alg' => 'straw',
       'hash' => 'rjenkins1',
       'id' => -4,
       'items' => [],
       'name' => 'ceph003',
       'type_id' => 1,
       'type_name' => 'host',
       'weight' => 0
     },
     {
       'alg' => 'straw',
       'hash' => 'rjenkins1',
       'id' => -5,
       'items' => [
         {
           'id' => -2,
           'pos' => 0,
           'weight' => 2862612
         },
         {
           'id' => -3,
           'pos' => 1,
           'weight' => 2862612
         }
       ],
       'name' => 'test1',
       'type_id' => 2,
       'type_name' => 'rack',
       'weight' => 5725224
     },
     {
       'alg' => 'straw',
       'hash' => 'rjenkins1',
       'id' => -6,
       'items' => [
         {
           'id' => -4,
           'pos' => 0,
           'weight' => 0
         }
       ],
       'name' => 'test2',
       'type_id' => 2,
       'type_name' => 'rack',
       'weight' => 0
     }
   ],
   'devices' => [
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 1,
       'name' => 'osd.1'
     },
     {
       'id' => 2,
       'name' => 'osd.2'
     },
     {
       'id' => 3,
       'name' => 'osd.3'
     },
     {
       'id' => 4,
       'name' => 'osd.4'
     },
     {
       'id' => 5,
       'name' => 'osd.5'
     },
     {
       'id' => 6,
       'name' => 'osd.6'
     },
     {
       'id' => 7,
       'name' => 'osd.7'
     },
     {
       'id' => 8,
       'name' => 'osd.8'
     },
     {
       'id' => 9,
       'name' => 'osd.9'
     },
     {
       'id' => 10,
       'name' => 'osd.10'
     },
     {
       'id' => 11,
       'name' => 'osd.11'
     },
     {
       'id' => 12,
       'name' => 'osd.12'
     },
     {
       'id' => 13,
       'name' => 'osd.13'
     },
     {
       'id' => 14,
       'name' => 'osd.14'
     },
     {
       'id' => 15,
       'name' => 'osd.15'
     },
     {
       'id' => 16,
       'name' => 'osd.16'
     },
     {
       'id' => 17,
       'name' => 'osd.17'
     },
     {
       'id' => 18,
       'name' => 'osd.18'
     },
     {
       'id' => 19,
       'name' => 'osd.19'
     },
     {
       'id' => 20,
       'name' => 'osd.20'
     },
     {
       'id' => 21,
       'name' => 'osd.21'
     },
     {
       'id' => 22,
       'name' => 'osd.22'
     },
     {
       'id' => 23,
       'name' => 'osd.23'
     },
     {
       'id' => 24,
       'name' => 'osd.24'
     },
     {
       'id' => 25,
       'name' => 'osd.25'
     },
     {
       'id' => 26,
       'name' => 'osd.26'
     },
     {
       'id' => 27,
       'name' => 'osd.27'
     },
     {
       'id' => 28,
       'name' => 'osd.28'
     },
     {
       'id' => 29,
       'name' => 'osd.29'
     },
     {
       'id' => 30,
       'name' => 'osd.30'
     },
     {
       'id' => 30,
       'name' => 'osd.30'
     },
     {
       'id' => 31,
       'name' => 'osd.31'
     },
     {
       'id' => 32,
       'name' => 'osd.32'
     },
     {
       'id' => 33,
       'name' => 'osd.33'
     },
     {
       'id' => 34,
       'name' => 'osd.34'
     },
     {
       'id' => 35,
       'name' => 'osd.35'
     }
   ],
   'rules' => [
     {
       'max_size' => 10,
       'min_size' => 1,
       'rule_id' => 0,
       'rule_name' => 'data',
       'ruleset' => 0,
       'steps' => [
         {
           'item' => -1,
           'op' => 'take'
         },
         {
           'num' => 0,
           'op' => 'chooseleaf_firstn',
           'type' => 'host'
         },
         {
           'op' => 'emit'
         }
       ],
       'type' => 1
     },
     {
       'max_size' => 10,
       'min_size' => 1,
       'rule_id' => 1,
       'rule_name' => 'metadata',
       'ruleset' => 1,
       'steps' => [
         {
           'item' => -1,
           'op' => 'take'
         },
         {
           'num' => 0,
           'op' => 'chooseleaf_firstn',
           'type' => 'host'
         },
         {
           'op' => 'emit'
         }
       ],
       'type' => 1
     },
     {
       'max_size' => 10,
       'min_size' => 1,
       'rule_id' => 2,
       'rule_name' => 'rbd',
       'ruleset' => 2,
       'steps' => [
         {
           'item' => -1,
           'op' => 'take'
         },
         {
           'num' => 0,
           'op' => 'chooseleaf_firstn',
           'type' => 'host'
         },
         {
           'op' => 'emit'
         }
       ],
       'type' => 1
     }
   ],
   'tunables' => {
     'choose_local_fallback_tries' => 5,
     'choose_local_tries' => 2,
     'choose_total_tries' => 19,
     'chooseleaf_descend_once' => 0
   },
   'types' => [
     {
       'name' => 'osd',
       'type_id' => 0
     },
     {
       'name' => 'host',
       'type_id' => 1
     },
     {
       'name' => 'rack',
       'type_id' => 2
     },
     {
       'name' => 'row',
       'type_id' => 3
     },
     {
       'name' => 'room',
       'type_id' => 4
     },
     {
       'name' => 'datacenter',
       'type_id' => 5
     },
     {
       'name' => 'root',
       'type_id' => 6
     }
   ]
); 
Readonly::Hash our %CMPMAP => (
   'buckets' => [
     {
       'alg' => 'straw',
       'items' => [
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         }
       ],
       'hash' => '0',
       'id' => -2,
       'name' => 'ceph001',
       'type' => 'host',
       'weight' => 12
     },
     {
       'alg' => 'straw',
       'items' => [
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         }
       ],
       'hash' => '0',
       'id' => -3,
       'name' => 'ceph002',
       'type' => 'host',
       'weight' => 12
     },
     {
       'alg' => 'straw',
       'items' => [
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         },
         {
           'name' => 'osd.0',
           'weight' => '1'
         }
       ],
       'hash' => '0',
       'id' => -4,
       'name' => 'ceph003',
       'type' => 'host',
       'weight' => 12
     },
     {
       'alg' => 'straw',
       'items' => [
         {
           'name' => 'ceph001',
           'weight' => 12
         },
         {
           'name' => 'ceph002',
           'weight' => 12
         },
         {
           'name' => 'ceph003',
           'weight' => 12
         }
       ],
       'hash' => '0',
       'defaultalg' => 'straw',
       'defaulthash' => '0',
       'id' => -1,
       'name' => 'default',
       'type' => 'root',
       'weight' => 36
     }
   ],
   'devices' => [
     {
       'id' => 0,
       'name' => 'osd.0'
     },
     {
       'id' => 1,
       'name' => 'osd.1'
     },
     {
       'id' => 2,
       'name' => 'osd.2'
     },
     {
       'id' => 3,
       'name' => 'osd.3'
     },
     {
       'id' => 4,
       'name' => 'osd.4'
     },
     {
       'id' => 5,
       'name' => 'osd.5'
     },
     {
       'id' => 6,
       'name' => 'osd.6'
     },
     {
       'id' => 7,
       'name' => 'osd.7'
     },
     {
       'id' => 8,
       'name' => 'osd.8'
     },
     {
       'id' => 9,
       'name' => 'osd.9'
     },
     {
       'id' => 10,
       'name' => 'osd.10'
     },
     {
       'id' => 11,
       'name' => 'osd.11'
     },
     {
       'id' => 12,
       'name' => 'osd.12'
     },
     {
       'id' => 13,
       'name' => 'osd.13'
     },
     {
       'id' => 14,
       'name' => 'osd.14'
     },
     {
       'id' => 15,
       'name' => 'osd.15'
     },
     {
       'id' => 16,
       'name' => 'osd.16'
     },
     {
       'id' => 17,
       'name' => 'osd.17'
     },
     {
       'id' => 18,
       'name' => 'osd.18'
     },
     {
       'id' => 19,
       'name' => 'osd.19'
     },
     {
       'id' => 20,
       'name' => 'osd.20'
     },
     {
       'id' => 21,
       'name' => 'osd.21'
     },
     {
       'id' => 22,
       'name' => 'osd.22'
     },
     {
       'id' => 23,
       'name' => 'osd.23'
     },
     {
       'id' => 24,
       'name' => 'osd.24'
     },
     {
       'id' => 25,
       'name' => 'osd.25'
     },
     {
       'id' => 26,
       'name' => 'osd.26'
     },
     {
       'id' => 27,
       'name' => 'osd.27'
     },
     {
       'id' => 28,
       'name' => 'osd.28'
     },
     {
       'id' => 29,
       'name' => 'osd.29'
     },
     {
       'id' => 30,
       'name' => 'osd.30'
     },
     {
       'id' => 30,
       'name' => 'osd.30'
     },
     {
       'id' => 31,
       'name' => 'osd.31'
     },
     {
       'id' => 32,
       'name' => 'osd.32'
     },
     {
       'id' => 33,
       'name' => 'osd.33'
     },
     {
       'id' => 34,
       'name' => 'osd.34'
     },
     {
       'id' => 35,
       'name' => 'osd.35'
     },
   ],
   'rules' => [
     {
       'name' => 'data',
       'max_size' => '10',
       'min_size' => '0',
       'ruleset' => 0,
       'type' => 'replicated',
       'steps' => [
         {
           'choices' => [
             {
               'bktype' => 'host',
               'number' => '0',
               'chtype' => 'chooseleaf firstn'
             }
           ],
           'take' => 'default'
         }
       ]
     },
     {
       'name' => 'metadata',
       'max_size' => '10',
       'min_size' => '0',
       'ruleset' => 1,
       'type' => 'replicated',
       'steps' => [
         {
           'choices' => [
             {
               'bktype' => 'host',
               'number' => '0',
               'chtype' => 'chooseleaf firstn'
             }
           ],
           'take' => 'default'
         }
       ]
     },
     {
       'max_size' => '10',
       'min_size' => '0',
       'name' => 'rbd',
       'ruleset' => 2,
       'type' => 'replicated',
       'steps' => [
         {
           'choices' => [
             {
               'bktype' => 'host',
               'number' => '0',
               'chtype' => 'chooseleaf firstn'
             }
           ],
           'take' => 'default'
         }
       ]
     }
   ],
   'types' => [
     {
       'name' => 'osd',
       'type_id' => 0
     },
     {
       'name' => 'host',
       'type_id' => 1
     },
     {
       'name' => 'root',
       'type_id' => 2
     }
   ]
);
Readonly our $WRITEMAP => <<END;
# begin crush map

# devices
device 0 osd.0
device 1 osd.1
device 2 osd.2
device 3 osd.3
device 4 osd.4
device 5 osd.5
device 6 osd.6
device 7 osd.7
device 8 osd.8
device 9 osd.9
device 10 osd.10
device 11 osd.11
device 12 osd.12
device 13 osd.13
device 14 osd.14
device 15 osd.15
device 16 osd.16
device 17 osd.17
device 18 osd.18
device 19 osd.19
device 20 osd.20
device 21 osd.21
device 22 osd.22
device 23 osd.23
device 24 osd.24
device 25 osd.25
device 26 osd.26
device 27 osd.27
device 28 osd.28
device 29 osd.29
device 30 osd.30
device 30 osd.30
device 31 osd.31
device 32 osd.32
device 33 osd.33
device 34 osd.34
device 35 osd.35

# types
type 0 osd
type 1 host
type 2 root

# buckets
host ceph001 {
	id -2		# do not change unnecessarily
	# weight 12
	alg straw
	hash 0	# rjenkins1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
}
host ceph002 {
	id -3		# do not change unnecessarily
	# weight 12
	alg straw
	hash 0	# rjenkins1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
}
host ceph003 {
	id -4		# do not change unnecessarily
	# weight 12
	alg straw
	hash 0	# rjenkins1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
	item osd.0 weight 1
}
root default {
	id -1		# do not change unnecessarily
	# weight 36
	alg straw
	hash 0	# rjenkins1
	item ceph001 weight 12
	item ceph002 weight 12
	item ceph003 weight 12
}

# rules
rule data {
	ruleset 0
	type replicated
	min_size 0
	max_size 10
	step take default
	step chooseleaf firstn 0 type host
	step emit
}
rule metadata {
	ruleset 1
	type replicated
	min_size 0
	max_size 10
	step take default
	step chooseleaf firstn 0 type host
	step emit
}
rule rbd {
	ruleset 2
	type replicated
	min_size 0
	max_size 10
	step take default
	step chooseleaf firstn 0 type host
	step emit
}

# end crush map
END

Readonly our $BASEMAP => <<END;
# begin crush map
tunable test_tune 0

# devices

# types
type  
type  
type  

# buckets
root default {
	id 		# do not change unnecessarily
	# weight 
	alg 
	hash 
}

# rules
rule data {
	ruleset 
	type 
	min_size 
	max_size 
	step take default
	step chooseleaf firstn  type host
	step emit
}
rule metadata {
	ruleset 
	type 
	min_size 
	max_size 
	step take default
	step chooseleaf firstn  type host
	step emit
}
rule rbd {
	ruleset 
	type 
	min_size 
	max_size 
	step take default
	step chooseleaf firstn  type host
	step emit
}

# end crush map
END

