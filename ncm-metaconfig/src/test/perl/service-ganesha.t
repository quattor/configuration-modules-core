use Test::More;
use Test::Quattor::TextRender::Metaconfig;

my $u = Test::Quattor::TextRender::Metaconfig->new(
        service => 'ganesha',
        version => '1.5',
        )->test();

my $v = Test::Quattor::TextRender::Metaconfig->new(
        service => 'ganesha',
        version => '2.2',
        )->test();

done_testing;
