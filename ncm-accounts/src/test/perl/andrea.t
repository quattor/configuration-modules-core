#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::NoWarnings;
use Test::Quattor qw(andreas_bug);
use NCM::Component::accounts;
use Readonly;
use CAF::Object;

Test::NoWarnings::clear_warnings();

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
tss:x:59:59:Account used by the trousers package to sandbox the tcsd::
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
:x:::::
EOF

Readonly my $GROUP => << 'EOF';
bin:x:1:bin,root,daemon
floppy:x:19:icomefromldapohyeah
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

=pod

=head1 SYNOPSIS

This is the test suite for two bugs reported by Andrea Chierici.

In his layout, he uses ncm-accounts mostly for setting up root password
and parameters.

It seems under these circumstances lots of undefined warnings and
collissions happen. First thing is to enable Test::NoWarnings

Next, he sometimes adds an account that comes from ldap to some
specific local group (i.e, specialization for some hosts).

We check that as well.

=cut

my $cmp = NCM::Component::accounts->new('accounts');
my $cfg = get_config_for_profile('andreas_bug');

set_file_contents("/etc/passwd", $PASSWD);
set_file_contents("/etc/group", $GROUP);
set_file_contents("/etc/shadow", $SHADOW);

is($cmp->Configure($cfg), 1, "Configuration works");

my $fh = get_file("/etc/group");
like($fh, qr{:icomefromldap\w+$}m,
     "Account coming from LDAP but having a local group is kept with remove_unknown=true");
$fh = get_file("/etc/passwd");
unlike($fh, qr{:::}, "Empty user is removed");
