# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.  Ensure the methods are
called when they have configurations associated, and that the daemon
is restarted when needed.

=cut

use strict;
use warnings;
use Test::More tests => 1;
use Test::Quattor qw(simple);
use NCM::Component::cron;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;

$CAF::Object::NoAction = 1;
$LC::Check::NoAction = 1;

my $cmp = NCM::Component::cron->new('NCM::Component::cron');

=pod

=head1 Tests for the cron component

=cut

my $cfg = get_config_for_profile('simple');
$cmp->Configure($cfg);
is($cmp->Configure($cfg), 1, "Normal execution succeeds");

