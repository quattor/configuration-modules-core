# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;

use Readonly;
use Test::More;
use Test::Quattor qw(noaction);
use NCM::Component::spma::yum;
use CAF::Object;

my $cfg = get_config_for_profile("noaction");

# How to test NoAction actually changes stuff?

=pod

=head1 What to test

=over

=item files/dirs are copied, permissions on tmppath are restricted

=cut


=pod

=item yum.conf points to tmppath

=cut


=pod

=item commands use new yum.conf

=cut


=pod

=back

=cut

done_testing();
