use strict;
use warnings;

use Test::More;
use Test::Quattor qw(simple);
use Test::Quattor::Object;
use CAF::Object;
use Test::MockModule;

my $mock = Test::MockModule->new('NCM::Component::grub');

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::grub->new("grub");
my $cfg = get_config_for_profile("simple");

ok(! defined($cmp->Configure($cfg)),
   "configure returns undef with missing default kernel");

set_file_contents('/boot/vmlinuz-1.2.3', 'something');
ok(! defined($cmp->Configure($cfg)),
   "configure returns undef with missing grubby");

set_file_contents('/sbin/grubby', 'something');

ok(! defined($cmp->Configure($cfg)), "configure returns undef with missing default kernel");

set_desired_output('/sbin/grubby --default-kernel --bad-image-okay', "/boot/vmlinuz-0.0.1\n");
command_history_reset();
ok(! defined($cmp->Configure($cfg)), "configure returns undef when failing to set correct default kernel");
ok(command_history_ok([
   '/sbin/grubby --default-kernel --bad-image-okay',
   '/sbin/grubby --set-default /boot/vmlinuz-1.2.3',
   '/sbin/grubby --default-kernel --bad-image-okay',
   '/sbin/grubby --set-default /boot/vmlinuz-0.0.1',
   '/sbin/grubby --default-kernel --bad-image-okay',
]), 'grubby commands from failed configure; failed to set default kernel');


set_desired_output('/sbin/grubby --default-kernel --bad-image-okay', "/boot/vmlinuz-1.2.3\n");
command_history_reset();
ok($cmp->Configure($cfg), "configure returns success");
ok(command_history_ok([
   '/sbin/grubby --default-kernel --bad-image-okay',
   '/sbin/grubby --update-kernel /boot/vmlinuz-1.2.3 --args a c --remove-args b',
]), 'grubby commands from succesful configure, default kernel already ok');


done_testing;
