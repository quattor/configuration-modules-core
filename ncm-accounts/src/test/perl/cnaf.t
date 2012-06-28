#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings qw(had_no_warnings);
use Test::Quattor qw(cnaf);
use NCM::Component::accounts;
use Readonly;
use CAF::Object;

$CAF::Object::NoAction = 1;

Readonly my $PASSWD => << 'EOF';
root:x:0:1:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/
EOF

Readonly my $GROUP => << 'EOF';
root:x:0:
bin:x:1:bin,daemon
daemon:x:2:bin,daemon
sys:x:3:bin,adm
adm:x:4:adm,daemon
EOF

Readonly my $SHADOW => << 'EOF';
root:$6$myveryweakpassword:15329:0:99999:7:::
bin:*:15209:0:99999:7:::
daemon:*:15209:0:99999:7:::
adm:*:15209:0:99999:7:::
lp:*:15209:0:99999:7:::
EOF

my $cmp = NCM::Component::accounts->new('accounts');

my $cfg = get_config_for_profile('cnaf');

my $t = $cfg->getElement("/software/components/accounts")->getTree();

set_file_contents("/etc/passwd", $PASSWD);
set_file_contents("/etc/group", $GROUP);
set_file_contents("/etc/shadow", $SHADOW);

my $sys = $cmp->build_system_map();

my $root = $cmp->compute_root_user($sys, $t);

is($root->{shell}, $t->{rootshell},
   "CNAF's setup inherits the correct shell for root");
is($root->{password}, $t->{rootpwd},
   "CNAF's setup inherits the correct password for root");
