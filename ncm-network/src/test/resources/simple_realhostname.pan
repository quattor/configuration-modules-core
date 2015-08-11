object template simple_realhostname;

include 'pan/types';
include 'components/network/core-schema';

bind "/system/network" = structure_network;


"/system/network" = create("defaultnetwork");
"/system/network/interfaces/eth0" = create("defaultinterface");

"/system/network/realhostname" = "realhost.example.com";
