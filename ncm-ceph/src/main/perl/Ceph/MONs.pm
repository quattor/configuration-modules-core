#${PMpre} NCM::Component::Ceph::MONs${PMpost}

use 5.10.1;


# Gets the MON map
sub mon_hash {
    my ($self) = @_;
    my $jstr = $self->{Cluster}->run_ceph_command([qw(mon dump)], 'get mon map') or return;
    my $monsh = decode_json($jstr);
    foreach my $mon (@{$monsh->{mons}}){
        $self->add_existing('mon', $mon->{name}, { addr => $mon->{addr }});
    }
    return 1;
}

sub mgr_hash 
{
    my ($self) = @_;
    my $jstr = $self->{Cluster}->run_ceph_command([qw(mgr dump)], 'get mgr map') or return;
    my $mgrsh = decode_json($jstr);
    $self->add_existing('mgr', $mgrsh->{active_name});
    foreach my $mgr (@{$mgrsh->{standbys}}){
        $self->add_existing('mgr', $mgr->{name});
    }
    return 1;
}

# Compare and change mon config
sub check_mon {
    my ($self, $hostname) = @_; 
    $self->debug(3, "Comparing mon $hostname");
    my $ceph_mon = $self->{ceph}->{$hostname}->{mon};
    if ($ceph_mon->{addr} =~ /^0\.0\.0\.0:0/) { 
        $self->debug(4, "Recreating initial (unconfigured) mon $hostname");
        return $self->add_daemon('mon', $hostname);
    }   
    my $donecmd = ['test','-e',"/var/lib/ceph/mon/ceph-$hostname/done"];
    if (!$self->{Cluster}->run_command_as_ceph_with_ssh($donecmd, $self->get_fqdn($hostname))) {
        # Node reinstalled without first destroying it
        $self->info("Previous mon $hostname shall be reinstalled");
        return $self->add_daemon('mon', $hostname);
    }   

    return 1;
}

