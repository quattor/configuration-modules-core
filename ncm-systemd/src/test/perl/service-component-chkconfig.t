use strict;
use warnings;

BEGIN {
    # do not use fake Test::Quattor ncm namespace
    # it does not support inheritance properly
    use Test::Quattor::Namespace;
    $Test::Quattor::Namespace::ignore->{ncm} = 1;
}

use Test::More;
use Test::Quattor qw(service-component-chkconfig);
use NCM::Component::Systemd::Service::Component::chkconfig;
use helper;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut


set_output("runlevel_5");
set_output("chkconfig_list_test");

my $cfg = get_config_for_profile('service-component-chkconfig');
my $cmp = NCM::Component::Systemd::Service::Component::chkconfig->new('systemd-component-chkconfig');

diag explain $cmp, $cmp->{NAME}, $cmp->name();
is($cmp->prefix(), '/software/components/systemd', "Correct prefix forced");

is_deeply($cmp->skip($cfg),
          { service => 0, random => 1 },
          "Skip all but service");

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

done_testing();
