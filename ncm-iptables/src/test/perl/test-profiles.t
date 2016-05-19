#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::Quattor qw(basic comment);
use NCM::Component::iptables;
use Test::More;
use CAF::Object;

$CAF::Object::NoAction = 1;
$NCM::Component::iptables::NoAction = 1;

my $comp = NCM::Component::iptables->new('iptables');


# Test profile which exercises basic functionality
my $cfg = get_config_for_profile('basic');

$comp->Configure($cfg);
ok(!exists($comp->{ERROR}), "No errors found with test profiles");

my $fh = get_file("/etc/sysconfig/iptables");
ok(defined($fh), "iptables config file was opened");
is("$fh", '# Firewall configuration written by ncm-iptables
# Manual modifications will be overwritten on the next NCM run.
*filter
:INPUT DROP [0:0]
:OUTPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
-A INPUT -s 10.0.0.0/8 -j ACCEPT
-A INPUT --match state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT --in-interface lo -j ACCEPT
COMMIT
', "test profile dropbydefault rendered correctly");


# Test profile with per-rule comments
$cfg = get_config_for_profile('comment');
$comp->Configure($cfg);

$fh = get_file("/etc/sysconfig/iptables");
ok(defined($fh), "iptables config file was opened");
like("$fh", qr(\s--comment "Private IP space"\s), "comment 1 rendered correctly");
like("$fh", qr(\s--comment Internal\s), "comment 2 rendered correctly");
undef $cfg;


done_testing();
