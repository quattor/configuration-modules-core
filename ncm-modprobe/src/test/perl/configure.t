# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Description

Unit test for the C<Configure> method.

No real work is done here.  We only ensure the logic is correct and
the appropriate methods are called.

=cut

use strict;
use warnings;
use Test::Quattor qw(modprobe);
use NCM::Component::modprobe;
use CAF::Object;
use Test::MockObject::Extends;
use Test::More;
use Class::Inspector;

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

my $cmp = NCM::Component::modprobe->new("modprobe");

$cmp = Test::MockObject::Extends->new($cmp);

no warnings 'redefine';

my @methods = grep($_ =~ m{^process|mkinitr},
                   @{Class::Inspector->functions("NCM::Component::modprobe")});

foreach my $method (@methods) {
    $cmp->mock($method, sub {
                   my $self = shift;
                   $self->{uc($method)}++;
               });
}

my $cfg = get_config_for_profile("modprobe");

$cmp->Configure($cfg);

foreach my $i (@methods) {
    is($cmp->{uc($i)}, 1, "Method $i was called");
}

$cmp->Configure($cfg);
foreach my $method (@methods) {
    if ($method =~ m{mkinitrd}) {
        is($cmp->{uc($method)}, 1, "mkinitrd is not called if there are no changes");
    } else {
        is($cmp->{uc($method)}, 2, "Method $method is called inconditionally");
    }
}


done_testing();
