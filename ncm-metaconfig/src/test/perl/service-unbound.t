use Test::More;
use Test::Quattor::TextRender::Metaconfig;

my $u = Test::Quattor::TextRender::Metaconfig->new(
    service => 'unbound',
)->test();

done_testing;
