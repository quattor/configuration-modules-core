# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<mkinitrd> method.

Ensures the C<mkinitrd> command will be executed for all the
C<System.map> files present in a directory.

=cut

use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Quattor;
use LC::File;
use subs 'NCM::Component::modprobe::directory_contents';
use NCM::Component::modprobe;
use CAF::FileWriter;
use CAF::Object;

use constant MKINITRD => "mkinitrd -f /boot/initrd-2.6.35.img 2.6.35";


my $mock = Test::MockModule->new('NCM::Component::modprobe');

$mock->mock('directory_contents', sub ($) {return [qw(foo System.map-2.6.35)]});

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::modprobe->new("modprobe");


$cmp->mkinitrd();

my $cmd = get_command(MKINITRD);
ok(defined($cmd), "mkinitrd was caled");

set_command_status(MKINITRD, 1);

$cmp->mkinitrd();
is($cmp->{ERROR}, 1, "Errors in mkinitrd are reported");


done_testing();
