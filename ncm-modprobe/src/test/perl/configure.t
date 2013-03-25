# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1

Basic test that ensures that our module will load correctly.

B<Do not disable this test>. And do not push anything to SF without
having run, at least, this test.

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

my $cmp = NCM::Component::modprobe->new("modprobe");

$cmp = Test::MockObject::Extends->new($cmp);

no warnings 'redefine';

my $i = 1;

sub CAF::FileWriter::close
{
    my ($self, $file, %opts) = @_;

    return $i--;
}


my @methods = grep($_ =~ m{^process|mkinitr},
                   @{Class::Inspector->functions("NCM::Component::modprobe")});

foreach my $i (@methods) {
    $cmp->mock($i, sub {
                   my $self = shift;
                   $self->{uc($i)}++;
               });
}

my $cfg = get_config_for_profile("modprobe");

$cmp->Configure($cfg);

foreach my $i (@methods) {
    is($cmp->{uc($i)}, 1, "Method $i was called");
}

$cmp->Configure($cfg);
foreach my $i (@methods) {
    if ($i =~ m{mkinitrd}) {
        is($cmp->{uc($i)}, 1, "mkinitrd is not called if there are no changes");
    } else {
        is($cmp->{uc($i)}, 2, "Method $i is called inconditionally");
    }
}


done_testing();
