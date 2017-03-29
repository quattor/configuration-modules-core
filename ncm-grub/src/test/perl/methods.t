use strict;
use warnings;

use Test::More;
use Test::Quattor qw(password);
use Test::Quattor::Object;
use CAF::Object;
use Test::MockModule;
use Readonly;

my $mock = Test::MockModule->new('NCM::Component::grub');

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::grub->new("grub");

=head1 grubby_args_options

=cut

is_deeply([$cmp->grubby_args_options()], [], "undef args returns empty options list");
is_deeply([$cmp->grubby_args_options("a -b c")],
          ['--args', 'a c', '--remove-args', 'b'],
          "args returns options list");
is_deeply([$cmp->grubby_args_options("a -b c", 1)],
          ['--mbargs', 'a c', '--remove-mbargs', 'b'],
          "args returns multiboot options list");

=head1 grub_conf / password

=cut

Readonly my $GRUBCFGFN => '/boot/grub/grub.conf';
Readonly my $GRUB2USERCFGFN => '/boot/grub2/user.cfg';

Readonly my $GRUBCFG => <<'EOF';
# some header
#

blah blah

title abc

EOF

Readonly my $GRUB2USERCFG => <<'EOF';
GRUB2_PASSWORD=1234
EOF

Readonly my $NEWGRUBCFG => <<'EOF';
# some header
#
password --encrypted 1234
terminal serial console
serial --unit=0 --speed=5678 --parity=n --word=8

blah blah

title abc

EOF

set_file_contents($GRUBCFGFN, "$GRUBCFG");

my $passwdcfg = get_config_for_profile("password");

$NCM::Component::grub::GRUB_MAJOR = 2;

$cmp->grub_conf($passwdcfg);
my $grubfh = get_file($GRUB2USERCFGFN);
isa_ok($grubfh, 'CAF::FileEditor', 'grub2 user.cfg is an editor instance');
is("$grubfh", $GRUB2USERCFG, "grub2 user.cfg edited as expected");

$NCM::Component::grub::GRUB_MAJOR = 1;

is($cmp->grub_conf($passwdcfg),
   "console=ttyS0,5678n8",
   "grub_conf returns console kernel parameters (if any)");
$grubfh = get_file($GRUBCFGFN);
isa_ok($grubfh, 'CAF::FileEditor', "grub config file is an editor instance");

is("$grubfh", "$NEWGRUBCFG", "grub cfg edited as expected");

=head1 grubby

=cut

set_desired_output('/sbin/grubby a b c', "the output\n");
is($cmp->grubby([qw(a b c)]), "the output\n", "default grubby returns output");

is($cmp->grubby([qw(a b c)], success => 1), 1, "success option returns 1 on success");
set_command_status('/sbin/grubby a b c', 5);

is($cmp->grubby([qw(a b c)], success => 1), 0, "success option returns 0 on failure");

my $proc = $cmp->grubby([qw(a b c)], proc => 1);
isa_ok($proc, 'CAF::Process', 'proc option return CAF::Process instance');
is_deeply($proc->{COMMAND}, [qw(/sbin/grubby a b c)], "passed args are added to command attribute");
is($proc->{NoAction}, 1, "NoAction set (via CAF::Object::NoAction at begin of tests)");

$proc = $cmp->grubby([], proc => 1, keeps_state => 1);
isa_ok($proc, 'CAF::Process', 'proc option return CAF::Process instance 2');
is($proc->{NoAction}, 0, "NoAction set to 0 via keeps_state");

=head1 current_default

=cut

Readonly my $DEFAULT_KERNEL => '/boot/vmlinuz-1.0.0';
Readonly my $OTHER_KERNEL => '/boot/somethingelse';
set_desired_output('/sbin/grubby --default-kernel --bad-image-okay', "$DEFAULT_KERNEL\n");

is($cmp->current_default(), '/boot/vmlinuz-1.0.0', "current default returned");

=head1 set_default

=cut

command_history_reset();
# set the kernel;
# grubby returns success; the queried verion is the already active default kernel
ok($cmp->set_default($DEFAULT_KERNEL), "set default kernel returns success");
ok(command_history_ok([
   "grubby --set-default $DEFAULT_KERNEL",
   'grubby --default-kernel --bad-image-okay',
]), "expected commands run with set_default");

command_history_reset();
# set the other kernel;
# grubby returns success, but default is not changed
ok(! $cmp->set_default($OTHER_KERNEL), "set default kernel returns failure");
ok(command_history_ok([
   "grubby --set-default $OTHER_KERNEL",
   'grubby --default-kernel --bad-image-okay',
]), "expected commands run set default failed");

=head1 configure_default

=cut

Readonly my $MB_KERNEL => '/boot/somethingmbish';
# add an alias to make things clearer
Readonly my $ORIGINAL => $DEFAULT_KERNEL;

command_history_reset();
# set the kernel;
# grubby returns success; the queried verion is the already active default kernel
# other kernel is the original (and should not be called in any way)
ok($cmp->configure_default($ORIGINAL, $MB_KERNEL, $ORIGINAL),
   "configure default kernel returns success");
ok(command_history_ok([
   "grubby --set-default $ORIGINAL",
   'grubby --default-kernel --bad-image-okay',
   ], ["$OTHER_KERNEL", "$MB_KERNEL"]),
   "expected commands run with succesful configure default");

command_history_reset();
# try to set the other kernels
# grubby returns success, but default is not changed
# tries to use the 2nd argumnet (mb kernel) with original value, which will succeed
# in particular there's no revert with 3rd arg (in this case the MBKERNEL)
ok($cmp->configure_default($OTHER_KERNEL, $ORIGINAL, $MB_KERNEL),
   "configure default kernel succesful with mb kernel");
ok(command_history_ok([
   "grubby --set-default $OTHER_KERNEL",
   'grubby --default-kernel --bad-image-okay',
   "grubby --set-default $ORIGINAL",
   'grubby --default-kernel --bad-image-okay',
   ], ["$MB_KERNEL"]),
   "expected commands run configure default failed on new and success with mb");

command_history_reset();
# try to set the other kernels
# grubby returns success, but default is not changed
# at the end, there's an attempt to revert to previous original
ok(! $cmp->configure_default($OTHER_KERNEL, $MB_KERNEL, $ORIGINAL),
   "configure default kernel returns failure");
ok(command_history_ok([
   "grubby --set-default $OTHER_KERNEL",
   'grubby --default-kernel --bad-image-okay',
   "grubby --set-default $MB_KERNEL",
   'grubby --default-kernel --bad-image-okay',
   "grubby --set-default $ORIGINAL",
   ]),
   "expected commands run configure default failed on new and mb, followed by revert");

=head1 kernel

=cut

my $kernel = {
    kernelpath => '/vmlinuz-1.2.3',
    kernelargs => 'a -b c -d console=ttyS1234 e f',
    multiboot => '/dunno',
    mbargs => 'mba -mbb mbc',
    initrd => '/some/file',
    title => 'superkernel',
};

command_history_reset();
# commands to test the kernels using --info return success by default
# so this is an update first
ok($cmp->kernel($kernel, '/boot', 'console=myconsole'), 'kernel settings returns SUCCESS update');
ok(command_history_ok([
  '/sbin/grubby --info /boot/vmlinuz-1.2.3',
  '/sbin/grubby --info /boot/dunno',
  '/sbin/grubby --update-kernel /boot/vmlinuz-1.2.3 --args a c e f console=myconsole --remove-args b d --add-multiboot /boot/dunno --mbargs mba mbc --remove-mbargs mbb',
]), 'grubby commands from kernel settings update');


command_history_reset();
set_command_status('/sbin/grubby --info /boot/vmlinuz-1.2.3', 5);
set_command_status('/sbin/grubby --info /boot/dunno', 5);
# commands to test the kernels using --info fail
# so now this is adding a new entry
ok($cmp->kernel($kernel, '/boot', 'console=myconsole'), 'kernel settings returns SUCCESS add');
ok(command_history_ok([
  '/sbin/grubby --info /boot/vmlinuz-1.2.3',
  '/sbin/grubby --info /boot/dunno',
  '/sbin/grubby --add-kernel /boot/vmlinuz-1.2.3 --title superkernel --args a c e f console=myconsole --remove-args b d --initrd /boot/some/file --add-multiboot /boot/dunno --mbargs mba mbc --remove-mbargs mbb',
]), 'grubby commands from kernel settings add');


=head1 default_info

=cut

my $info_kernel = '/boot/vmlinuz-1.2.3-4.56';
my $info = <<"EOF";
index=0
kernel=$info_kernel
args="ro rhgb"
root=UUID=hihi-haha
initrd=/boot/initramfs-1.2.3-4.56.img
title=CentOS Linux (1.2.3-4.56) 7 (Core)
index=1
kernel=$info_kernel
args="ro rhgb somethingelse"
root=UUID=hihi-haha
initrd=/boot/initramfs-1.2.3-4.56.img
title=CentOS Linux (1.2.3-4.56) 7 (Core) with debugging
EOF

set_desired_output("/sbin/grubby --info $info_kernel", $info);
command_history_reset();
my $res = $cmp->get_info($info_kernel);
diag explain $res;
is_deeply($res, [{
    args => '"ro rhgb"',
    index => 0,
    initrd => '/boot/initramfs-1.2.3-4.56.img',
    kernel => $info_kernel,
    root => 'UUID=hihi-haha',
    title => 'CentOS Linux (1.2.3-4.56) 7 (Core)',
    }, {
    args => '"ro rhgb somethingelse"',
    index => 1,
    initrd => '/boot/initramfs-1.2.3-4.56.img',
    kernel => $info_kernel,
    root => 'UUID=hihi-haha',
    title => 'CentOS Linux (1.2.3-4.56) 7 (Core) with debugging',
    }], "return info arrayref");
ok(command_history_ok(["/sbin/grubby --info $info_kernel"]), "get_info uses grubby --info");

=head1 default_options

=cut

command_history_reset();
# start with non-fullcontrol
# no --info call
ok($cmp->default_options({args => 'a -b c'}, '/boot/vmlinuz-1.2.3.4'), "default_options returns success on non-fullcontrol");
ok(command_history_ok([
   '/sbin/grubby --info /boot/vmlinuz-1.2.3.4',
   '/sbin/grubby --update-kernel /boot/vmlinuz-1.2.3.4 --args a c --remove-args b',
]), 'grubby commands from default options non-fullcontrol');

command_history_reset();
# fullcontrol, existing options will not match;
# but there are current args to remove first
# settings args with a - with fullcontrol is pointless; all current args are removed first
set_desired_output('/sbin/grubby --info /boot/vmlinuz-1.2.3.4', "blablah\nargs=\"something special\"\nkernel=/boot/vmlinuz-1.2.3.4\n");
ok($cmp->default_options({fullcontrol => 1, args => 'a -b c'}, '/boot/vmlinuz-1.2.3.4'), "default_options returns success on non-fullcontrol");
ok(command_history_ok([
   '/sbin/grubby --info /boot/vmlinuz-1.2.3.4',
   '/sbin/grubby --update-kernel /boot/vmlinuz-1.2.3.4 --remove-args something special',
   '/sbin/grubby --update-kernel /boot/vmlinuz-1.2.3.4 --args a c --remove-args b',
]), 'grubby commands from default options fullcontrol');

done_testing;
