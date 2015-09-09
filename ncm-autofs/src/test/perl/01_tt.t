use strict;
use warnings;
use Test::More;
use Test::Quattor::TextRender::Component;
my $t = Test::Quattor::TextRender::Component->new(
    component => 'autofs')->test();
done_testing();
