#${PMcomponent}

use parent qw(NCM::Component);

=head1 NAME

ncm-${project.artifactId}: Configuration module for Cororsync/Pacemaker using pcs

=head2 Methods

=over

=cut

=item Configure

component Configure method

=cut

sub Configure
{
    my ($self, $config) = @_;

    return 1;
}

=pod

=back

=cut

1;
