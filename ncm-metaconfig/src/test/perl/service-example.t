use Test::Quattor::ProfileCache qw(set_json_typed get_json_typed);
BEGIN {
    set_json_typed()
}

ok(get_json_typed(), "json_typed enabled for correct metadata");

use Test::More;
use Test::Quattor::TextRender::Metaconfig;
my $u = Test::Quattor::TextRender::Metaconfig->new(
        service => 'example',
        )->test();
done_testing;
