use strict;
use warnings;

use Test::More;
use Test::Quattor::TextRender::Component;

my $t = Test::Quattor::TextRender::Component->new(
    component => 'ceph')->test();

done_testing();
