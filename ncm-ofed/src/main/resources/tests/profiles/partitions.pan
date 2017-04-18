object template partitions;

include 'components/ofed/schema';

bind '/' = component_ofed_partition{};
'/default/ipoib' = true;
'/default/rate' = 7;
'/default/mtu' = 5;
'/default/properties/0/guid' = 'ALL';
'/default/properties/0/membership' = 'full';
'/vlan1/key' = 1023;
'/vlan1/properties/0/guid' = 'ALL_SWITCHES';
'/vlan1/properties/0/membership' = 'limited';
'/vlan1/properties/1/guid' = '0x12345';
'/vlan1/properties/1/membership' = 'both';
