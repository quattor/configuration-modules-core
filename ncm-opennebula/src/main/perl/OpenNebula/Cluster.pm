#${PMpre} NCM::Component::OpenNebula::Cluster${PMpost}

use Readonly;

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


=pod

=back

=cut

1;
