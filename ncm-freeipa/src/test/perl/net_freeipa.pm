use strict;
use warnings;

use Test::More;
use Test::MockModule;

my $rc = Test::MockModule->new('Rest::Client');
my $json = Test::MockModule->new('JSON::XS');
my $nic = Test::MockModule->new('Net::FreeIPA::RPC');

$json->mock('decode_json', {
    my ($self, $hostname, %opts) = @_;
    $self>{rc} = $RC;
});

our 

1;
