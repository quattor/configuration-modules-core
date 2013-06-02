object template basic;

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

"shorewall" = nlist();
