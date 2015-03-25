use strict;
use warnings;
use Test::More;
use Test::Quattor::TextRender::Component;

my $t = Test::Quattor::TextRender::Component->new(
    component => 'opennebula')->test();

done_testing();
