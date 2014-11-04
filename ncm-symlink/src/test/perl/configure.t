# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the Configure of the symlink component

=cut


use strict;
use warnings;
use Test::More;
use Test::Quattor qw(basic dupes);
use NCM::Component::symlink;
use CAF::Object;
use Readonly;

use Test::MockModule;

our $links = {};
my $mock = Test::MockModule->new('NCM::Component::symlink');
$mock->mock('process_link', sub {
        my ($self, $link, $href) = @_;
        $links->{$link}=$href->{target}->getValue();
        return 1;
        });

$CAF::Object::NoAction = 1;

my $cfg;
my $cmp = NCM::Component::symlink->new('symlink');

=pod

=head2 Test Configure

Test the Configure of the symlink component. Test if the expected 
links are processed and no errors or warnings are logged.

=cut

$cfg = get_config_for_profile('basic');
is($cmp->Configure($cfg), 1, "Basic Configure returns 1");
is_deeply($links, {"/link1" => "target1", "/link2" => "target2"}, "process_link processed links");
ok(! defined($cmp->{ERROR}), "No error is reported");
ok(! defined($cmp->{WARN}), "No warning is reported");

=pod

=head2 Test duplicate link

Test the behaviour of the component when duplicate links
are defined in the template. The last defined of the dupes 
is the link actually set, and a warning is logged.

=cut


$links = {};
$cfg = get_config_for_profile('dupes');
is($cmp->Configure($cfg), 1, "Dupes Configure returns 1");
# process last link1 with 
is_deeply($links, {"/link1" => "target1b", "/link2" => "target2"}, "process_link processed link dupes");
# check for logged error
ok(! defined($cmp->{ERROR}), "No error is reported");
is($cmp->{WARN}, 1, "Warning is reported");


done_testing();
