object template basic;

function pkg_repl = { null; };
include 'components/shorewall/config';
# remove the dependencies
'/software/components/shorewall/dependencies' = null;

prefix "/software/components/shorewall";

"interfaces/0/zone" = "z1";
"interfaces/0/interface" = "eth0";

"zones/0/zone" = "z1";
"zones/0/type" = "ipv4";

"policy/0/src" = "z1";
"policy/0/dst" = "all";
"policy/0/policy" = "accept";

"rules/0/action" = "ACCEPT";
"rules/0/src/zone" = "z1";
"rules/0/src/address/0" = "1.2.3.4";
"rules/0/dst/zone" = "fw";
"rules/0/dst/address/0" = "5.6.7.8";
"rules/0/dstport/0" = "23";

"shorewall" = dict();

"tcinterfaces/0/interface" = "eth0";

"tcpri/0/band" = 3;
"tcpri/0/address" = "1.2.3.4/32";

"masq/0/dest" = list('eth0');
"masq/0/source" = 'eth1';

"snat/0/action" = "SNAT(10.10.20.30)";
"snat/0/source" = '0.0.0.0/0';
"snat/0/dest" = list('eth2');

"providers/0/name" = "isp1";
"providers/0/number" = 2;
"providers/0/interface" = "abc";
"providers/0/gateway" = "1.2.3.4";
"providers/0/options" = list('track', 'balance');

"rtrules/0/provider" = "isp1";
"rtrules/0/priority" = 1000;
