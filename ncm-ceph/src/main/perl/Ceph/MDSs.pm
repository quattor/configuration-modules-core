#${PMpre} NCM::Component::Ceph::MDSs${PMpost}

use 5.10.1;


# Gets the MDS map
sub mds_hash {
    my ($self) = @_;
    my $jstr = $self->{Cluster}->run_ceph_command([qw(mds stat)]) or return 0;
    my $mdshs = decode_json($jstr);
    my $fsmap = $mdshs->{fsmap};
    foreach my $fs (@{$fsmap->{filesystems}}){
        foreach my $mds (values %{$fs->{mdsmap}->{info}}) {
            $self->add_existing('mds', $mds->{name});
        }
    }
    foreach my $mds (@{$fsmap->{standbys}}){
        $self->add_existing('mds', $mds->{name});
    }

    return 1;
}

