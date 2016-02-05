use Test::More;
use Test::Quattor::TextRender::Metaconfig;
use XML::Parser;

my $u = Test::Quattor::TextRender::Metaconfig->new(
    service => 'icinga-web',
)->test();

done_testing;
