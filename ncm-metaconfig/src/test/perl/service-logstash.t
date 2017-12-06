use Test::More;
use Test::Quattor::TextRender::Metaconfig;

my $u12 = Test::Quattor::TextRender::Metaconfig->new(
        service => 'logstash',
        version => '1.2',
        )->test();

my $u20 = Test::Quattor::TextRender::Metaconfig->new(
        service => 'logstash',
        version => '2.0',
        )->test();

my $u50 = Test::Quattor::TextRender::Metaconfig->new(
        service => 'logstash',
        version => '5.0',
        )->test();


done_testing;
