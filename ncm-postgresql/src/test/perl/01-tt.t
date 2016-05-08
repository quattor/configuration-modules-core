use strict;
use warnings;

use Test::Quattor::ProfileCache qw(set_json_typed get_json_typed);
BEGIN {
    set_json_typed()
}

use Test::More;
use Test::Quattor::TextRender::Component;

my $t = Test::Quattor::TextRender::Component->new(
    component => 'postgresql')->test();

done_testing();
