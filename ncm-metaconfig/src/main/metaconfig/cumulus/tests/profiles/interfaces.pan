object template interfaces;

@{MLAG example config}

include 'metaconfig/cumulus/interfaces';

prefix "/software/components/metaconfig/services/{/etc/network/interfaces}/contents/interfaces";
"lo" = dict(
    'inet', 'loopback',
    'address', '10.0.0.11',
    'mask', 32,
    'bridge', dict('enable', false),
);

"eth0" = dict(
    'inet', 'dhcp',
    'bridge', dict('enable', false),
    'vrf', 'mgmt',
);

# one leg of dual connected, one to each MLAG member
"server1" = dict(
    'slaves', list('swp1'),
    'clag-id', 1,
);
"server2" = dict(
    'slaves', list('swp2'),
    'clag-id', 2,
    'bond-lacp-bypass-allow', true,
    'mstpctl-bpduguard', true,
);

"swp3" = dict(
    'alias', 'some port',
    'bridge', dict('access', 123, 'pvid', 14),
    'link', dict('autoneg', true, 'speed', 10),
    'vrf', 'test3',
);

prefix "/software/components/metaconfig/services/{/etc/network/interfaces}/contents/peerlink";
"slaves" = list('swp50', 'swp51');
"address" = "169.254.1.1";
"mask" = 30;
"clagd/peer-ip" = "169.254.1.2";
"clagd/sys-mac" = "44:38:39:FF:00:01";
"clagd/backup-ip/ip" = "1.2.3.4";
"clagd/backup-ip/vrf" = "mgmt";


prefix "/software/components/metaconfig/services/{/etc/network/interfaces}/contents/bridge";
"vlan-aware" = true;
"pvid" = 12;
"vids" = list(1, 5, 12, 18, 40, 98, 100);
"stp" = false;
"mcsnoop" = false;
