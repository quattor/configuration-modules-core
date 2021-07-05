use Test::More;
use Test::Quattor::TextRender::Metaconfig;
use EDG::WP4::CCM::TextRender;

my $u = Test::Quattor::TextRender::Metaconfig->new(
    service => 'nova',
)->test();

done_testing();
