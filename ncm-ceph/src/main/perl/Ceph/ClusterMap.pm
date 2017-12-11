#${PMpre} NCM::Component::Ceph::ClusterMap${PMpost}

use 5.10.1;

use parent qw(CAF::Object NCM::Component::Ceph::MONs NCM::Component::Ceph::MDSs);
use Readonly;
use Data::Dumper;

sub _initialize
{
    my ($self, $clusterobj) = @_;

    $self->{log} = $clusterobj;

    $self->{quattor} = [];
    $self->{ceph} = [];

    $self->{actions} = {
        hash => {
            mon => \&mon_hash,
            mgr => \&mgr_hash,
            mds => \&mds_hash,
        },
    };
    $self->{Cluster} = $clusterobj;
    return 1;
}

sub get_fqdn
{
    my ($self, $host) = @_;
    return $self->{quattor}->{$host}->{fqdn};
};

sub get_quattor_map
{
    my ($self) = @_;
    return $self->{quattor};
}

sub add_existing
{
    my ($self, $type, $name, $daemon) = @_;
    # Only one type per host, name hostname
    $self->{ceph}->{$name}->{$type} = $daemon ||= {};
}

sub add_quattor
{
    my ($self, $type, $name, $daemon) = @_;
    # Only one type per host
    $self->{quattor}->{$name}->{$type} = $daemon;
    $self->{quattor}->{$name}->{fqdn} = $daemon->{fqdn};
    
}

sub map_existing
{
    my ($self) = @_;
    foreach my $type ( sort keys %{$self->{actions}->{hash}}){
        $self->{actions}->{hash}->{$type}($self->{Cluster});
    }   
    $self->debug(5, "Existing ceph hash:", Dumper($self->{ceph}));
}

sub map_quattor
{
    my ($self) = @_; 
    my $quattor = $self->{Cluster}->{cluster};
    $self->debug(2, "Building information from quattor");
    while (my ($hostname, $mon) = each(%{$quattor->{monitors}})) {
        $hostname =~ s/\..*//;;
        $self->add_quattor('mon', $hostname, $mon);
        $self->add_quattor('mgr', $hostname, $mon); # add a mgr for each mon
    }   
    while (my ($hostname, $mds) = each(%{$quattor->{mdss}})) {
        $hostname =~ s/\..*//;;
        $self->add_quattor('mds', $hostname, $mds);
    }   
    $self->debug(5, "Quattor hash:", Dumper($self->{quattor}));
}

sub compare_host
{
    my ($self, $host) = @_;

    my %qt = %{$self->{quattor}->{$host}};
    my %ceph = %{$self->{ceph}->{$host}};

    foreach my $typ (%qt) {
        if ($ceph{$typ}){
            if ($typ eq 'mon'){
                # Check for ghost monitor
                $self->check_mon($host);
            };
            delete $ceph{$typ};
        } else {
            $self->verbose("Configuring new $typ $host");
            $self->add_daemon($typ, $host);
        }
    }
    if (%ceph) {
        $self->error("Found deployed daemons on node $host that are not in config: ", sort keys(%ceph));
    }
        
}

# host not existing, add host to deploy
# daemon not existing -> add daemon
# mon existing, verify mon
# report leftovers
sub compare_maps
{
    my ($self) = @_;
    my %qt = %{$self->{quattor}};
    my %ceph = %{$self->{ceph}};
    foreach my $host (sort keys(%qt)) {
        if ($ceph{$host}){
            $self->compare_host($host);
            delete $ceph{$host};
        } else {
            $self->verbose("Configuring new host $host");
            $self->{deploy}->{$host} = $qt{$host};
        };
    }
    if (%ceph) {
        $self->warn('Found deployed nodes that are not in config: ', sort keys(%ceph));
    }
}


1;
