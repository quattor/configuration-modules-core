#${PMpre} NCM::Component::Ceph::Cluster${PMpost}

use 5.10.1;

use parent qw(CAF::Object NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use Readonly;
use JSON::XS;
use Data::Dumper;


sub _initialize
{
    my ($self, $cfgtree, $log, $prefix) = @_;

    $self->{log} = $log;
    $self->{cfgtree} = $cfgtree;
    $self->{prefix} = $prefix;
    $self->{config} = $cfgtree->getTree($self->{prefix});

    return 1;
}

1;

sub configure
{
    my ($self) = @_;

    return ;
};
