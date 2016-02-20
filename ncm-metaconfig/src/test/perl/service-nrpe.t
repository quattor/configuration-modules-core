use Test::Quattor::ProfileCache qw(set_json_typed get_json_typed);
BEGIN {
    set_json_typed()
}
use Test::More;
use Test::Quattor::TextRender::Metaconfig;

ok(get_json_typed(), "json_typed enabled for nrpe render");

my $u = Test::Quattor::TextRender::Metaconfig->new(
    service => 'nrpe',
)->test();

done_testing;
