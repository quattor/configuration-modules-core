use Test::More;
use Test::Quattor::TextRender::Metaconfig;

my $u = Test::Quattor::TextRender::Metaconfig->new(
    service => 'kafka',
    usett => 0, # uses builtin modules
)->test();

done_testing;
