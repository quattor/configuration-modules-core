# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(simple_services);
use File::Path qw(mkpath);
use NCM::Component::chkconfig;
use Test::MockModule;


$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

my $cfg = get_config_for_profile('simple_services');
my $cmp = NCM::Component::chkconfig->new('chkconfig');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");


done_testing();
