package OpenstackMock;

use Test::MockModule;
use Test::More;
use Data::Dumper;
use base 'Exporter';
use XML::Simple;
use Cwd;
use version;


# DEBUG only (can't get the output in unittests otherwise)
sub dlog
{
    my ($type, @args) = @_;
    diag("[".uc($type)."] ".join(" ", @args));
}

our $nco = Test::MockModule->new('NCM::Component::openstack');
foreach my $type ("error", "info", "verbose", "debug", "warn") {
    $nco->mock( $type, sub { shift; dlog($type, @_); } );
}

# To test usage of TT files during regular component use.
my $mock = Test::MockModule->new('CAF::TextRender');
$mock->mock('new', sub {
    my $init = $mock->original("new");
    my $trd = &$init(@_);
    $trd->{includepath} = [getcwd()."/target/share/templates/quattor"];
    return $trd;
});

1;
