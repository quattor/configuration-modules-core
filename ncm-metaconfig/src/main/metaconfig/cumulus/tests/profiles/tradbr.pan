object template tradbr;

@{traditional bridges, see "vlan tagging adv example" config}

include 'metaconfig/cumulus/interfaces';

prefix "/software/components/metaconfig/services/{/etc/network/interfaces}/contents";

prefix "interfaces";
"bond2" = dict(
    'slaves', list('swp4', 'swp5', 'swp6', 'swp7'),
);

prefix "bridges/untagged";
"ports" = list("swp1", "bond2");
"stp" = true;
"address" = "10.0.0.1";
"mask" = 24;

prefix "bridges/tag100";
"ports" = list("swp1", "swp2", "bond2");
"vid" = 100;
"stp" = true;
"address" = "10.0.100.1";
"mask" = 24;
"vrf" = "test100";

prefix "bridges/vlan120";
"ports" = list("swp2", "swp3", "bond2");
"vid" = 120;
"stp" = true;
"address" = "10.0.120.1";
"mask" = 24;

prefix "bridges/v130";
"ports" = list("swp3", "bond2.140");  # using mixed vlans here (see vlan translation)
"vid" = 130;
"stp" = true;
"address" = "10.0.130.1";
"mask" = 24;
