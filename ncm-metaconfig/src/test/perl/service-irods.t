use Test::More;
use Test::Quattor::TextRender::Metaconfig;
my $u = Test::Quattor::TextRender::Metaconfig->new(
    service => 'irods',
    usett => 0,
    )->test();
done_testing;

