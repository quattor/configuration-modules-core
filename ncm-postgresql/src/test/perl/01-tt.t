use strict;
use warnings;

use Test::More;
use Test::Quattor::TextRender::Component;

my $t = Test::Quattor::TextRender::Component->new(
    component => 'postgresql')->test();

done_testing();
