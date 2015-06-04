use Test::Quattor::ProfileCache qw(set_json_typed get_json_typed);

BEGIN {
    set_json_typed()
}


use Test::More;
use Test::Quattor::TextRender::Metaconfig;

ok(get_json_typed(), "json_typed enabled for yaml render");

my $u = Test::Quattor::TextRender::Metaconfig->new(
        service => 'elasticsearch',
        usett => 0, # uses builtin modules
        )->test();

done_testing;
