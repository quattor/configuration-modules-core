#${PMpre} NCM::Component::Ceph::ClusterMap${PMpost}

use parent qw(CAF::Object);
use Readonly;
use Data::Dumper;
use JSON::XS;


sub _initialize
{
    my ($self, $clusterobj) = @_;

    $self->{log} = $clusterobj;

    $self->{quattor} = {};
    $self->{ceph} = {};

    $self->{Cluster} = $clusterobj;
    $self->{deploy} = {};
    return 1;
}

sub get_fqdn
{
    my ($self, $host) = @_;
    return $self->{quattor}->{$host}->{fqdn};
};

# get the parsed daemons as they are declared in schema
sub get_quattor_map
{
    my ($self) = @_;
    return $self->{quattor};
}

# Gets the MON map
sub mon_hash
{
    my ($self) = @_;
    my ($ec, $jstr) = $self->{Cluster}->run_ceph_command([qw(mon dump)], 'get mon map', nostderr => 1) or return;
    my $monsh = decode_json($jstr);
    foreach my $mon (@{$monsh->{mons}}){
        $self->add_existing('mon', $mon->{name}, {addr => $mon->{addr}});
    }
    return 1;
}

# Gets the MGR map
sub mgr_hash
{
    my ($self) = @_;
    my ($ec, $jstr) = $self->{Cluster}->run_ceph_command([qw(mgr dump)], 'get mgr map', nostderr => 1) or return;
    my $mgrsh = decode_json($jstr);
    $self->add_existing('mgr', $mgrsh->{active_name});
    foreach my $mgr (@{$mgrsh->{standbys}}){
        $self->add_existing('mgr', $mgr->{name});
    }
    return 1;
}

# Gets the MDS map
sub mds_hash
{
    my ($self) = @_;
    my ($ec, $jstr) = $self->{Cluster}->run_ceph_command([qw(mds stat)], 'get mds map', nostderr => 1) or return;
    my $mdshs = decode_json($jstr);
    my $fsmap = $mdshs->{fsmap};
    foreach my $fs (@{$fsmap->{filesystems}}){
        foreach my $mds (sort values %{$fs->{mdsmap}->{info}}) {
            $self->add_existing('mds', $mds->{name});
        }
    }
    foreach my $mds (@{$fsmap->{standbys}}){
        $self->add_existing('mds', $mds->{name});
    }

    return 1;
}

# Compare and change mon config
sub check_mon
{
    my ($self, $hostname, $mon) = @_;
    $self->debug(3, "Comparing mon $hostname");
    my $ceph_mon = $self->{ceph}->{$hostname}->{mon};
    if ($ceph_mon->{addr} =~ /^0\.0\.0\.0:0/) {
        #This is a corner case seen with an earlier version. when something goes wrong,
        #the ceph-mon can be in a weird existing not configured state.
        $self->debug(4, "Recreating initial (unconfigured) mon $hostname");
        return $self->add_daemon('mon', $hostname, $mon);
    }
    my $donecmd = ['test', '-e', "/var/lib/ceph/mon/ceph-$hostname/done"];
    if (!$self->{Cluster}->run_command_as_ceph_with_ssh($donecmd, $self->get_fqdn($hostname), 'verify monitor exists')) {
        # Node reinstalled without first destroying it
        $self->info("Previous mon $hostname shall be reinstalled");
        return $self->add_daemon('mon', $hostname, $mon);
    }

    return 1;
}

# Add a daemon to the existing daemon map
sub add_existing
{
    my ($self, $type, $name, $daemon) = @_;
    # Only one type per host, name hostname
    $self->debug(3, "Adding $type $name to existing map");
    $self->{ceph}->{$name}->{$type} = $daemon || {};
    return 1;
}

# add a daemon to the quattor map
sub add_quattor
{
    my ($self, $type, $name, $daemon) = @_;
    # Only one type per host
    $self->debug(3, "Adding $type $name to quattor map");
    $self->{quattor}->{$name}->{daemons}->{$type} = $daemon;
    $self->{quattor}->{$name}->{fqdn} = $daemon->{fqdn};
    return 1;
}

# add a daemon to the map to deploy
sub add_daemon
{
    my ($self, $type, $name, $daemon) = @_;
    $self->{deploy}->{$name}->{$type} = $daemon;
    $self->{deploy}->{$name}->{fqdn} = $self->{quattor}->{$name}->{fqdn};
    return 1;
}

# Add a host that needs deployment
sub add_host
{
    my ($self, $name, $host) = @_;
    $self->{deploy}->{$name} = $host->{daemons};
    $self->{deploy}->{$name}->{fqdn} = $host->{fqdn};
    return 1;
}

# Fill in the map with existing daemons
sub map_existing
{
    my ($self) = @_;
    my @actions = (\&mon_hash, \&mgr_hash, \&mds_hash);
    foreach my $type (@actions) {
        $type->($self) or return;
    }
    $self->debug(5, "Existing ceph hash:", Dumper($self->{ceph}));
    return 1;
}

# Fill in the map with daemons declared in schema
sub map_quattor
{
    my ($self) = @_;
    my $quattor = $self->{Cluster}->{cluster};
    $self->debug(2, "Building information from quattor");
    foreach my $hostname (sort keys %{$quattor->{monitors}}) {
        my $mon = $quattor->{monitors}->{$hostname};
        $hostname =~ s/\..*//;;
        $self->add_quattor('mon', $hostname, $mon);
        $self->add_quattor('mgr', $hostname, $mon); # add a mgr for each mon
    }
    foreach my $hostname (sort keys %{$quattor->{mdss}}) {
        my $mds = $quattor->{mdss}->{$hostname};
        $hostname =~ s/\..*//;;
        $self->add_quattor('mds', $hostname, $mds);
    }
    $self->debug(5, "Quattor hash:", Dumper($self->{quattor}));
    return 1;
}

# Compare all daemons of one host
sub compare_host
{
    my ($self, $host) = @_;

    my %qt = %{$self->{quattor}->{$host}->{daemons}};
    my %ceph = %{$self->{ceph}->{$host}};

    foreach my $typ (sort keys %qt) {
        if ($ceph{$typ}){
            if ($typ eq 'mon'){
                # Check for ghost monitor
                $self->check_mon($host, $qt{$typ});
            };
            delete $ceph{$typ};
        } else {
            $self->verbose("Configuring new $typ $host");
            $self->add_daemon($typ, $host, $qt{$typ});
        }
    }
    if (%ceph) {
        $self->error("Found deployed daemons on node $host that are not in config: ", join(',', sort keys(%ceph)));
    }
    return 1;
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
    foreach my $host (sort keys %qt) {
        if ($ceph{$host}){
            $self->compare_host($host);
            delete $ceph{$host};
        } else {
            $self->verbose("Configuring new host $host");
            $self->add_host($host, $qt{$host});
        };
    }
    if (%ceph) {
        $self->warn('Found deployed nodes that are not in config: ', sort keys(%ceph));
    }
    return 1;
}

# return the map that can be used to deploy new daemons
sub get_deploy_map
{
    my ($self) = @_;
    $self->compare_maps();
    return $self->{deploy};
}

1;
