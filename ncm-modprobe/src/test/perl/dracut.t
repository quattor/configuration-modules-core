# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<dracut> method.

Ensures the C<dracut> command will be executed for all the
C<System.map> files present in a directory.

=cut

use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Quattor;
use LC::File;
use NCM::Component::modprobe;
use CAF::FileWriter;
use CAF::Object;

use constant DRACUT => "dracut -f /boot/initrd-2.6.35.img 2.6.35";


my $mock = Test::MockModule->new('NCM::Component::modprobe');

$mock->mock('directory_contents', sub ($) {return [qw(foo System.map-2.6.35)]});

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::modprobe->new("modprobe");


$cmp->dracut();

my $cmd = get_command(DRACUT);
ok(defined($cmd), "dracut was called");

set_command_status(DRACUT, 1);

$cmp->dracut();
is($cmp->{ERROR}, 1, "Errors in dracut are reported");


done_testing();
