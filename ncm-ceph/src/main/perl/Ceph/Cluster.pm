#${PMpre} NCM::Component::Ceph::Cluster${PMpost}

use 5.10.1;

use parent qw(CAF::Object);

sub _initialize
{
    my ($self, $config, $log, $prefix) = @_;

    $self->{log} = $log;
    $self->{config} = $config;
    $self->{prefix} = $prefix;
    $self->{comptree} = $config->getTree($self->{prefix});

    return 1;
}

1;

