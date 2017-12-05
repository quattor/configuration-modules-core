#${PMpre} NCM::Component::Ceph::OSDserver${PMpost}

use 5.10.1;

use parent qw(CAF::Object);
use NCM::Component::Ceph::Cfgfile;

sub _initialize
{
    my ($self, $cfgtree, $log, $prefix) = @_;

    $self->{log} = $log;
    $self->{cfgtree} = $cfgtree;
    $self->{compprefix} = $prefix;
    $self->{prefix} = "$prefix/daemons/osds";
    $self->{config} = $cfgtree->getTree($self->{prefix});

    return 1;
}


sub configure
{
    my ($self) = @_;
    
    my $cfgfile = NCM::Component::Ceph::Cfgfile->new($self->cfgtree, $self->{compprefix});
    if (!$cfgfile->configure()) {
        $self->error('Could not write cfgfile, aborting deployment');
        return;
    }

    if (!$self->is_node_healthy()) {
        $self->error('Node not healthy, aborting deployment'); 
        return;
    }
    if (!$self->prepare_osds()){
        $self->error('osds could not be prepared, aborting deployment');
        return;
    }
    if (!$self->deploy()){
        $self->error('Something went wrong deploying osds');
        return;
    }
    if (!$self->do_post()){
        $self->error('Could not do post-deploy tasks');
        return;
    }
    return 1;
}

1;
