#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 23;
use Test::NoWarnings;
use Test::Quattor qw(cnaf);
use NCM::Component::accounts;
use Readonly;
use CAF::Object;

Test::NoWarnings::clear_warnings();

=pod

=head1 SYNOPSIS

This is the test suite for a bug reported by Andrea Chierici.

In his layout, the users and groups lists were empty. And a previous
version of the component had broken the specification for root.

Finally, root got its primary group changed.

=head1 FIX

The solution was to:

=over

=item * Have a default list for the groups root should belong to.

If a misconfiguration wiped out all its groups, the component is now
able to recover a useable rot account.

=item * Ensure that root's main group is always the
C<root> group, with GID 0.

This is now hardcoded in the component. Really, we don't want root to
ever have a different main group. Even if there's buggy software that
tries otherwise.

=cut

$CAF::Object::NoAction = 1;

Readonly my $PASSWD => << 'EOF';
root:x:0:1:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
uucp:x:10:14:uucp:/var/spool/uucp:/sbin/nologin
operator:x:11:0:operator:/root:/sbin/nologin
games:x:12:100:games:/usr/games:/sbin/nologin
gopher:x:13:30:gopher:/var/gopher:/sbin/nologin
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin
nobody:x:99:99:Nobody:/:/sbin/nologin
dbus:x:81:81:System message bus:/:/sbin/nologin
vcsa:x:69:69:virtual console memory owner:/dev:/sbin/nologin
ntp:x:38:38::/etc/ntp:/sbin/nologin
saslauth:x:499:76:"Saslauthd user":/var/empty/saslauth:/sbin/nologin
postfix:x:89:89::/var/spool/postfix:/sbin/nologin
haldaemon:x:68:68:HAL daemon:/:/sbin/nologin
sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin
tcpdump:x:72:72::/:/sbin/nologin
nagios:x:498:497::/var/spool/nagios:/sbin/nologin
rpc:x:32:32:Rpcbind Daemon:/var/cache/rpcbind:/sbin/nologin
tss:x:59:59:Account used by the trousers package to sandbox the tcsd
daemon:/dev/null:/sbin/nologin
abrt:x:173:173::/etc/abrt:/sbin/nologin
lemon:x:497:496:lemon user:/var/empty/lemon:/sbin/nologin
nrpe:x:496:495:NRPE user for the NRPE service:/:/sbin/nologin
ricci:x:140:140:ricci daemon user:/var/lib/ricci:/sbin/nologin
rpcuser:x:29:29:RPC Service User:/var/lib/nfs:/sbin/nologin
nfsnobody:x:65534:65534:Anonymous NFS User:/var/lib/nfs:/sbin/nologin
mailnull:x:47:47::/var/spool/mqueue:/sbin/nologin
smmsp:x:51:51::/var/spool/mqueue:/sbin/nologin
amandabackup:x:33:6:Amanda user:/var/lib/amanda:/bin/bash
uuidd:x:495:493:UUID generator helper daemon:/var/lib/libuuid:/sbin/nologin
ident:x:98:98::/:/sbin/nologin
sam:x:24459:30035:Sam Station:/home/sam:/bin/bash
EOF

Readonly my $GROUP => << 'EOF';
bin:x:1:bin,root,daemon
floppy:x:19:
lock:x:54:
lemon:x:496:
mailnull:x:47:
nobody:x:99:
tty:x:5:
lp:x:7:daemon,lp
postfix:x:89:
uuidd:x:493:
cdfsoft:x:30034:
nagios:x:497:
tss:x:59:
nfsnobody:x:65534:
ecryptfs:x:494:
sys:x:3:bin,root,adm
video:x:39:
cdrom:x:11:
haldaemon:x:68:haldaemon
ricci:x:140:
smmsp:x:51:
postdrop:x:90:
ident:x:98:
dbus:x:81:
tcpdump:x:72:
rpcuser:x:29:
dialout:x:18:
mem:x:8:
gopher:x:30:
wheel:x:10:root
cdfcaf:x:30035:sam
saslauth:x:76:
games:x:20:
disk:x:6:root
abrt:x:173:
users:x:100:
audio:x:63:
ftp:x:50:
tape:x:33:amandabackup
kmem:x:9:
root:x:0:root
utempter:x:35:
mail:x:12:postfix,mail
dip:x:40:
daemon:x:2:bin,root,daemon
stapusr:x:498:
slocate:x:21:
ntp:x:38:
uucp:x:14:uucp
rpc:x:32:
adm:x:4:root,daemon,adm
man:x:15:
nrpe:x:495:
vcsa:x:69:
utmp:x:22:
stapdev:x:499:
sshd:x:74:
EOF

Readonly my $SHADOW => << 'EOF';
root:$6$myveryweakpassword:15329:0:99999:7:::
bin:*:15209:0:99999:7:::
daemon:*:15209:0:99999:7:::
adm:*:15209:0:99999:7:::
lp:*:15209:0:99999:7:::
EOF

use constant LOGIN_DEFS => {};

sub init_test
{
    set_file_contents("/etc/passwd", $PASSWD);
    set_file_contents("/etc/group", $GROUP);
    set_file_contents("/etc/shadow", $SHADOW);
}

my $cmp = NCM::Component::accounts->new('accounts');

my $cfg = get_config_for_profile('cnaf');

my $t = $cfg->getElement("/software/components/accounts")->getTree();

init_test();


my $sys = $cmp->build_system_map(LOGIN_DEFS,'none');

my $root = $cmp->compute_root_user($sys, $t);



is($root->{shell}, $t->{rootshell},
   "CNAF's setup inherits the correct shell for root");
is($root->{password}, $t->{rootpwd},
   "CNAF's setup inherits the correct password for root");
is($root->{main_group}, 0, "Main group for root still kept");
$t->{users} = $cmp->compute_desired_accounts($t->{users});
is(scalar(keys(%{$t->{users}})), 0,
   "Undefined users list in the profile leads to empty (but defined) desired accounts");
$t->{users}->{root} = $root;

is($t->{users}->{root}->{main_group}, 0, "Upon computation, root's GID is 0");

$cmp->adjust_groups($sys, $t->{groups}, $t->{kept_groups});
is($sys->{passwd}->{root}->{main_group}, 1,
   "Group adjustment doesn't change the GID for root");
$cmp->adjust_accounts($sys, $t->{users}, $t->{kept_users});

is ($sys->{passwd}->{root}->{main_group}, 0,
    "Adjusting accounts re-adjusts properly the GID for root");

foreach my $i (qw(root daemon bin adm)) {
    ok(exists($sys->{groups}->{$i}), "Group $i still exists");
    ok(exists($sys->{groups}->{$i}->{members}), "Group $i has members");
    ok(exists($sys->{groups}->{$i}->{members}->{root}),
       "root account still belongs to group $i");
}


=pod

=head2 More checks

It seems this is not good enough. We'll have to ensure that a system
that starts off *without* root, has a correct root account.

=cut

init_test();
$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
delete($sys->{passwd}->{root});
$t = $cfg->getElement("/software/components/accounts")->getTree();
$root = $cmp->compute_root_user($sys, $t);
$t->{users} = $cmp->compute_desired_accounts($t->{users});
$t->{users}->{root} = $root;
$cmp->adjust_groups($sys, $t->{groups}, $t->{kept_groups});
$cmp->adjust_accounts($sys, $t->{users}, $t->{kept_users});
ok(exists($sys->{passwd}->{root}),
   "Root is created even when it doesn't exist");
is($sys->{passwd}->{root}->{main_group}, 0,
   "Re-generated root gest the correct main group");

Test::NoWarnings::had_no_warnings();
