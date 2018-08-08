#${PMpre} NCM::Component::OpenNebula::Cluster${PMpost}

use Readonly;
use Data::Dumper;

Readonly my $DEFAULT_CLUSTER => "default";

=head1 NAME

C<NCM::Component::OpenNebula::Cluster> adds C<OpenNebula> C<VirtualCluster>
configuration support to L<NCM::Component::opennebula>.

=head2 Public methods

=over

=item manage_clusters

Adds or removes clusters.

=cut

sub manage_clusters
{
    my ($self, $one, $type, $data, %protected) = @_;
    my $getmethod = "get_${type}s";
    my $createmethod = "create_${type}";
    my %temp;
}


=item set_service_clusters

Includes an specific service into a cluster/s

=cut

sub set_service_clusters
{
    my ($self, $one, $type, $service, $clusters) = @_;
    my (@delclusters, @addclusters);
    my %newclusters;

    my @existcluster = $one->get_clusters();

    if ($type eq 'host') {
        # Hosts only have a single cluster in a string
        %newclusters = map { $_ => 1 } split(/ /, $clusters);
    } else {
        %newclusters = map { $_ => 1 } @$clusters;
    };
    my $name = $service->name;

    # Remove/add the resource from the available clusters
    foreach my $cluster (@existcluster) {
        if (!exists($newclusters{$cluster->name})) {
            $self->info("$type $name does not require this cluster: ", $cluster->name);
            my $new = $cluster->del($service);
            push(@delclusters, $cluster->name) if defined($new);
        } else {
            $self->info("$type $name requires this cluster: ", $cluster->name);
            my $new = $cluster->add($service);
            push(@addclusters, $cluster->name) if defined($new);
        }
    }

    $self->info("$type $name was removed from these cluster(s): ", join(', ', @delclusters));
    $self->info("$type $name was included into these cluster(s): ", join(', ', @addclusters));

    return 1;
}


=pod

=back

=cut

1;
