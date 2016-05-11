use Test::More;
use Test::Quattor::TextRender::Metaconfig;

my $u22 = Test::Quattor::TextRender::Metaconfig->new(
        service => 'httpd',
        version => '2.2',
        )->test();

my $u24 = Test::Quattor::TextRender::Metaconfig->new(
        service => 'httpd',
        version => '2.4',
        )->test();

done_testing;
